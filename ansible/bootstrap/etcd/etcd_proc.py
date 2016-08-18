import os
import logging
import sys
import time
import json
import base64
import shutil
import etcd
import random
import subprocess
import boto.route53

class DnsCtl:

    REGION = os.environ['EC2_REGION']
    DOMAIN = os.environ['DOMAIN']
    MAX_MEMBERS = 5  # max number of members allowed in the cluster
    RECORD_TTL = 600  # number of seconds before marking the DNS record a invalid
    CLIENT_TTL = 100  # number of seconds before removing a hung member from DNS record

    def __init__(self, ip):
        self.conn = boto.route53.connect_to_region(self.REGION)
        self.zone = self.conn.get_zone(self.DOMAIN + '.')
        self.ip = ip

    def get_record(self):
        try:
            dns_record = self.zone.find_records('_' + self.REGION + '.' + self.DOMAIN, 'TXT')
            if dns_record:
                dns_record = dns_record.resource_records[0].strip('"')
                dns_record = json.loads(base64.b64decode(dns_record))
                if not isinstance(dns_record.get('ttl'), int) or \
                   not isinstance(dns_record.get('members'), list) or \
                   abs(time.time() - dns_record['ttl']) > self.RECORD_TTL:
                    return None
            return dns_record
        except Exception as e:
            logging.exception("Failed")
            return None

    def verify_record(self):
        dns_record = self.get_record()
        if dns_record:
            for member in dns_record['members']:
                ip, ttl, _ = member.split(':')
                if ip == self.ip and int(ttl) >= self.CLIENT_TTL / 2:
                    return dns_record
        return None

    def write_record(self, dns_record):
        txt = json.dumps(dns_record)
        change_set = boto.route53.record.ResourceRecordSets(self.conn, self.zone.id)
        change = change_set.add_change('UPSERT', '_' + self.REGION + '.' + self.DOMAIN, type="TXT", ttl=30)
        change.add_value('"' + base64.b64encode(bytes(txt)) + '"')
        change_set.commit()

        return self.verify_record()


    def set_record(self, dns_record, leader_ip):
        try:
            is_member = False
            ttl_diff = int(abs(time.time() - dns_record['ttl'])) + 1
            members = []

            for member in dns_record['members']:
                ip, ttl, is_leader = member.split(':')
                ttl = int(ttl)
                is_leader = bool(int(is_leader))

                if leader_ip:
                    is_leader = leader_ip == ip

                if ip == self.ip:
                    is_member = True
                    ttl = self.CLIENT_TTL
                else:
                    ttl -= ttl_diff

                if ttl > 0:
                    members += [ip + ':' + str(ttl) + ':' + str(int(is_leader))]

            if not is_member and len(members) < self.MAX_MEMBERS:
                is_member = True
                members += [self.ip + ':' + str(self.CLIENT_TTL) + ':' + str(int(self.ip == leader_ip))]

            if is_member:
                dns_record = {'ttl': int(time.time()), 'members': members}
                return self.write_record(dns_record)
            return dns_record

        except Exception as e:
            logging.exception("Failed")
            return None

    @staticmethod
    def init_record():
        return {"ttl": int(time.time()), "members": []}

    @staticmethod
    def get_leader_ip(dns_record):
        for member in dns_record['members']:
            ip, _, is_leader = member.split(':')
            if bool(int(is_leader)):
                return ip
        return None


class EtcdCtl:

    MIN_MEMBERS = 3
    DATA_DIR = os.environ['ETCD_DATA_DIR']
    CLIENT_PORT = int(os.environ['ETCD_CLIENT_PORT'])
    SERVER_PORT = int(os.environ['ETCD_SERVER_PORT'])

    def __init__(self, ip):
        self.etcd_proc = None
        self.ip = ip
        self.current_cluster_state = 'stopped'
        self.current_cluster_list = []

    def get_record(self, leader_ip):
        etcd_host = leader_ip
        if self.etcd_proc:
            etcd_host = '127.0.0.1'
        if etcd_host:
            try:
                etcd_client = etcd.Client(host=etcd_host, port=self.CLIENT_PORT, read_timeout=5)
                members = [ m.strip('https://').split(':')[0] for m in etcd_client.machines]
                leader = etcd_client.leader['clientURLs'][0].strip('https://').split(':')[0]
                return {'leader': leader, 'members': members}
            except Exception as e:
                logging.exception("Failed")
                pass
        return {'leader': leader_ip, 'members': []}

    @staticmethod
    def merge_record(etcd_record, dns_record):
        for member in dns_record['members']:
            ip, _, is_leader = member.split(':')
            if not ip in etcd_record['members']:
                etcd_record['members'] += [ip]
            if not etcd_record['leader'] and bool(int(is_leader)):
                etcd_record['leader'] = ip
        return etcd_record

    def stop_proc(self):
        if self.etcd_proc:
            try:
                self.etcd_proc.kill()
                self.etcd_proc.wait()
            except Exception as e:
                logging.exception("Failed")
                pass
        self.etcd_proc = None
        self.current_cluster_state = 'stopped'

    def build_initial_cluster(self, cluster_list):
        var = ""
        for member in cluster_list:
            var += member + '=http://' + member + ':' + str(self.SERVER_PORT) + ','
        var.rstrip(',')
        return var

    def build_endpoint(self, cluster_list):
        var = ""
        for member in cluster_list:
            if member != self.ip:
                var += 'http://' + member + ':' + str(self.CLIENT_PORT) + ','
        var.rstrip(',')
        return var

    def start_proc(self, cluster_list, cluster_state):
        os.environ['ETCD_INITIAL_CLUSTER'] = self.build_initial_cluster(cluster_list)

        if cluster_state == 'member':
            subprocess.call(['etcdctl',
                             '--endpoint',
                             self.build_endpoint(cluster_list),
                             'member',
                             'add',
                             self.ip,
                             os.environ['ETCD_INITIAL_ADVERTISE_PEER_URLS']])
            shutil.rmtree(self.DATA_DIR + '/proxy', ignore_errors=True)
            os.environ['ETCD_INITIAL_CLUSTER_STATE'] = 'existing'
            os.unsetenv('ETCD_PROXY')

        elif cluster_state == 'bootstrap':
            shutil.rmtree(self.DATA_DIR + '/member', ignore_errors=True)
            shutil.rmtree(self.DATA_DIR + '/proxy', ignore_errors=True)
            os.environ['ETCD_INITIAL_CLUSTER_STATE'] = 'new'
            os.unsetenv('ETCD_PROXY')

        else:
            shutil.rmtree(self.DATA_DIR + '/member', ignore_errors=True)
            os.unsetenv('ETCD_INITIAL_CLUSTER_STATE')
            os.environ['ETCD_PROXY'] = 'on'

        logging.info("Starting etcd process in %s mode - %s" % (cluster_state, cluster_list))
        self.etcd_proc = subprocess.Popen('/usr/local/bin/etcd')
        self.current_cluster_list = cluster_list
        self.current_cluster_state = cluster_state

    def check_proc(self, etcd_record):
        if not self.ip in etcd_record['members']:
            cluster_state = 'proxy'
        elif etcd_record['leader']:
            cluster_state = 'member'
        elif len(etcd_record['members']) >= self.MIN_MEMBERS:
            cluster_state = 'bootstrap'
        else:
            logging.error("not enough members in ETCD cluster - %s" % etcd_record['members'])
            return None

        if sorted(etcd_record['members']) != self.current_cluster_list or \
           cluster_state != self.current_cluster_state or \
           self.etcd_proc is None or not self.etcd_proc.poll() is None:
            self.stop_proc()
            self.start_proc(sorted(etcd_record['members']), cluster_state)


def run(dns_ctl, etcd_ctl, interval):

    dns_record = dns_ctl.get_record()
    if not dns_record:
        dns_record = dns_ctl.init_record()
    logging.info('DNS Record - %s' % dns_record)

    etcd_record = etcd_ctl.get_record(dns_ctl.get_leader_ip(dns_record))

    dns_record = dns_ctl.set_record(dns_record, etcd_record['leader'])
    if not dns_record:
        # DNS update failed, try again
        time.sleep(1)
    else:
        # DNS updated, start etcd process
        etcd_ctl.check_proc(etcd_ctl.merge_record(etcd_record, dns_record))
        time.sleep(interval)


if __name__ == "__main__":

    CHECK_INTERVAL = 10  # number of seconds between checks
    SELF_IP = os.environ['ETCD_NAME']

    DNS_CTL = DnsCtl(SELF_IP)
    ETCD_CTL = EtcdCtl(SELF_IP)
    ETCD_MONITOR = subprocess.Popen(['/bin/etcd_monitor.sh'])

    while True:

        if ETCD_MONITOR.poll() is not None:
            logging.critical("etcd monitor script died")
            sys.exit(1)

        run(DNS_CTL, ETCD_CTL, CHECK_INTERVAL)
	sys.stdout.flush()
