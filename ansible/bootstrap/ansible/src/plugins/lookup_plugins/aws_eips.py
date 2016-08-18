from time import sleep
import boto.ec2
import boto.route53
from ansible.errors import AnsibleError
from ansible.plugins.lookup import LookupBase

class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):
        region = terms[0]
        env = terms[1]
        domain = terms[2] + ('.' if terms[2][-1] != '.' else '')
        max_idx = 250

        ec2 = boto.ec2.connect_to_region(region)
        route53 = boto.route53.connect_to_region(region)
        if not ec2 or not route53:
            raise KeyError('Region not found - %s' % (region))
        zone = route53.get_zone(domain)
        if not zone:
            raise KeyError('Domain not found - %s' % (domain))

        # scan existing names
        names = [[False for x in range(max_idx)] for x in range(max_idx)]
        instances = ec2.get_only_instances(filters={'instance-state-name':'running'})
        for instance in instances:
            if 'Name' in instance.tags and instance.tags['env'] == env:
                tokens = instance.tags['Name'].split('-')
                names[int(tokens[1])][int(tokens[2])] = True

        # assign names to new instances
        for instance in instances:
            if 'Name' not in instance.tags and instance.tags['env'] == env:
                tokens = instance.private_ip_address.split('.')
                index = int(tokens[2])
                slot = 0
                while slot < max_idx:
                    if not names[index][slot]:
                        names[index][slot] = True
                        break
                    slot = slot + 1
                if slot >= max_idx:
                    raise AnsibleError('No free private IP in subnet %s:%d' % (region, index))
                instance.add_tag('Name', '%s-%d-%d' % (tokens[1], index, slot))

        # assign elastic IP address to instances
        eips = []
        for instance in instances:
            if not instance.ip_address and instance.tags['env'] == env:
                hostname = instance.tags['Name'] + '.' + domain

                # register new route53 record
                if not zone.get_a(hostname):
                    # todo: it's possible to leave an allocated epi dangling
                    #       should compare all eips in this region with records
                    #       found in route53 zone
                    addr = ec2.allocate_address().public_ip
                    zone.add_a(hostname, addr)

                # wait for route53 registration to finish
                max_wait = 90
                while not zone.get_a(hostname):
                    if max_wait <= 0:
                        raise AnsibleError('route53 add_a timed out - %s' % (hostname))
                    max_wait = max_wait - 1
                    sleep(1)

                # associate eip to instance
                addr = zone.get_a(hostname).resource_records[0]
                ec2.associate_address(instance_id=instance.id, public_ip=addr)
                eips.append(addr)

            elif instance.tags['env'] == env:
                eips.append(instance.ip_address)

        return eips
