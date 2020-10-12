import json
from botocore.exceptions import ClientError

from libs.connector import Connector


class RoleCreator(Connector):
    def __init__(self, role_name):
        super(RoleCreator, self).__init__('iam')   # srv_name is 'iam'
        self.role_name = role_name

    @classmethod
    def read_json_as_dict(cls, f_name):
        with open('jsons/'+f_name) as json_file:
            data = json.load(json_file)
            return data

    def attach_policy_to_role(self, policy_arn):
        iam_client = self.connect_aws_service()  # connect aws srv by srv_name
        try:
            attach_policy_res = iam_client.attach_role_policy(
                RoleName=self.role_name,
                PolicyArn=policy_arn
            )
            return attach_policy_res
        except ClientError as err:
            print('Unexpected error occurred ... clean up the role now')
            iam_client.delete_role(
                RoleName=self.role_name
            )
            return 'Role could not be created ...', err

    # You are not able to create role and attach policies in one request cause
    # the  quota for ACLSizePerRole: 2048' limitation
    def create_eks_iam_role(self, role_type):
        if role_type == 'cluster':
            iam_role_eks = self.read_json_as_dict('assume_eks_cluster.json')
        elif role_type == 'nodegroup':
            iam_role_eks = self.read_json_as_dict('assume_eks_nodegroup.json')
        else:
            print('role type not supported ...')

        iam_client = self.connect_aws_service()
        try:
            create_role_res = iam_client.create_role(
                RoleName=self.role_name,
                AssumeRolePolicyDocument=json.dumps(iam_role_eks),
                Tags=[
                    {
                        'Key': 'Creator',
                        'Value': 'eks_creation_helper'
                    }
                ]
            )
            return create_role_res
        except ClientError as err:
            if err.response['Error']['Code'] == 'EntityAlreadyExists':
                return 'Role already exists ... skip create it again ...'
            else:
                return 'Unexpected error occurred ...', err


class ClusterRoleCreator(RoleCreator):
    def __init__(self, cluster_name):
        super(ClusterRoleCreator, self).__init__(cluster_name)

    def create_role(self):
        return self.create_eks_iam_role('cluster')

    def attach_policy(self):
        # Policy of eks cluster
        pols = [
            'arn:aws:iam::aws:policy/AmazonEKSClusterPolicy'
        ]
        res = []
        for p in pols:
            res.append(self.attach_policy_to_role(p))
        return res


class NodegroupRoleCreator(RoleCreator):
    def __init__(self, nodegroup_name):
        super(NodegroupRoleCreator, self).__init__(nodegroup_name)

    def create_role(self):
        return self.create_eks_iam_role('nodegroup')

    def attach_policy(self):
        # Policies of eks nodegroup
        pols = [
            'arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy',
            'arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy',
            'arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly',
        ]
        res = []
        for p in pols:
            res.append(self.attach_policy_to_role(p))
        return res
