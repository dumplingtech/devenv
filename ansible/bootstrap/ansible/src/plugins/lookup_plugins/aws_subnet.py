import boto.vpc
from ansible.errors import AnsibleError
from ansible.plugins.lookup import LookupBase

class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):
        zone = terms[0]
        env = terms[1]

        region = zone[:-1]
        vpc = boto.vpc.connect_to_region(region)
        if not vpc:
            raise KeyError('Region not found - %s' % (region))

        for subnet in vpc.get_all_subnets(filters={'availabilityZone': zone}):
            if subnet.tags.has_key('env') and subnet.tags['env'] == env:
                return [subnet.id]
        raise AnsibleError('No subnet in zone %s:%s' % (zone, env))
