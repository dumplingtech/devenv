import boto.vpc
from ansible.errors import AnsibleError
from ansible.plugins.lookup import LookupBase

class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):
        region = terms[0]

        vpc = boto.vpc.connect_to_region(region)
        if not vpc:
            raise KeyError('Region not found - %s' % (region))

        vpcs = [vpc.id for vpc in vpc.get_all_vpcs()]
        if not vpcs:
            raise AnsibleError('No VPCs in region %s' % (region))

        return vpcs
