import re

from libs.roles import ClusterRoleCreator, NodegroupRoleCreator


def get_var_by_name(key):
    with open('NAMING_CONF') as fp:
        lines = fp.readlines()
        for line in lines:
            match = re.search(r'(\w+)=\'(\S+)\'', line)
            k, v = match[1], match[2]
            if k == key:
                return v


if __name__ == '__main__':
    # cluster_name = get_var_by_name('CLUSTER_NAME')
    eks_cluster_role = get_var_by_name('CLUSTER_ROLE_NAME')
    eks_nodegroup_role = get_var_by_name('NODE_ROLE_NAME')

    # Cluster Role Creator, Nodegroup Role Creator
    crc = ClusterRoleCreator(eks_cluster_role)
    ngc = NodegroupRoleCreator(eks_nodegroup_role)

    print('Creating EKS cluster role ...')
    crc_res = crc.create_role()
    print(crc_res)
    print('Attaching EKS cluster policy ...')
    crc_res = crc.attach_policy()
    print(crc_res)

    print('Creating EKS nodegroup role ...')
    ngc_res = ngc.create_role()
    print(ngc_res)
    print('Attaching EKS nodegroup policies ...')
    ngc_res = ngc.attach_policy()
    print(ngc_res)
