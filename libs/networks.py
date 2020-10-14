from botocore.exceptions import ClientError

from libs.connector import Connector


class NetworkCreator(Connector):
    def __init__(self, role_name):
        super(NetworkCreator, self).__init__('ec2')   # srv_name is 'ec2'
        self.response = None
        self.vpc = None
        self.igw = None
        self.rtb = None

    def create_vpc(self):
        # REF: https://bit.ly/3iSP4Ay
        # Create VPC, tagging
        ec2_client = self.connect_aws_service()
        try:
            create_vpc_res = ec2_client.create_vpc(
                CidrBlock='10.0.0.0/16',
                DryRun=False,
                InstanceTenancy='default',
                TagSpecifications=[
                    {
                        'ResourceType': 'vpc',
                        'Tags': [
                            {
                                'Key': 'Creator',
                                'Value': 'eks_creation_helper'
                            }
                        ]
                    }
                ]
            )
            self.response = create_vpc_res
            self.vpc = create_vpc_res['Vpc']['VpcId']
            return create_vpc_res
        except ClientError as err:
            print('Unexpected error occurred while creating VPC ...')
            return 'VPC could not be created', err

    def create_igw(self):
        # REF: https://bit.ly/34TdIMy
        # Create IGW, tagging
        ec2_client = self.connect_aws_service()
        try:
            create_igw_res = ec2_client.create_internet_gateway(
                DryRun=False,
                TagSpecifications=[
                    {
                        'ResourceType': 'internet-gateway',
                        'Tags': [
                            {
                                'Key': 'Creator',
                                'Value': 'eks_creation_helper'
                            }
                        ]
                    }
                ]
            )
            self.response = create_igw_res
            self.igw = create_igw_res['InternetGateway']['InternetGatewayId']
            return create_igw_res
        except ClientError as err:
            print('Unexpected error occurred while creating IGW ...')
            return 'IGW could not be created', err

    def attach_igw_to_vpc(self, igwid=None, vpcid=None):
        ec2_client = self.connect_aws_service()
        if not igwid:
            igwid = self.igw
        if not vpcid:
            vpcid = self.vpc
        try:
            attach_res = ec2_client.attach_internet_gateway(
                DryRun=False,
                InternetGatewayId=igwid,
                VpcId=vpcid
            )
            self.response = attach_res
            return attach_res
        except ClientError as err:
            print('Unexpected error occurred while attaching IGW and VPC ...')
            return 'IGW and VPC not attached', err

    def detach_igw(self, igwid=None, vpcid=None):
        ec2_client = self.connect_aws_service()
        if not igwid and self.igw:
            igwid = self.igw
        else:
            return

        if not vpcid and self.vpc:
            vpcid = self.vpc
        else:
            return

        try:
            attach_res = ec2_client.detach_internet_gateway(
                DryRun=False,
                InternetGatewayId=igwid,
                VpcId=vpcid
            )
            self.response = attach_res
            return attach_res
        except ClientError as err:
            print('Unexpected error occurred while detaching IGW / VPC ...')
            return 'IGW and VPC not detached', err

    def create_route_table_attach_igw(self, vpcid=None, igwid=None):
        # The routing rules of a vpc are associated withmultiples
        # 1. Create routing table associated to vpc
        ec2_client = self.connect_aws_service()
        if not vpcid and self.vpc:
            vpcid = self.vpc
        else:
            print('Missing VPC id')
            return

        try:
            rtb_res = ec2_client.create_route_table(
                DryRun=False,
                VpcId=vpcid,
                TagSpecifications=[
                    {
                        'ResourceType': 'route-table',
                        'Tags': [
                            {
                                'Key': 'Creator',
                                'Value': 'eks_creation_helper'
                            }
                        ]
                    }
                ]
            )
            self.response = rtb_res
            self.rtb = rtb_res['RouteTable']['RouteTableId']
        except ClientError as err:
            print('Unexpected error occurred while creating routing table...')
            return 'Routing Table not created', err

        # 2. add route to IGW
        if not igwid and self.igw:
            igwid = self.igw
        else:
            print('Missing Internet Gateway id')
            return

        try:
            add_route_to_igw_res = ec2_client.create_route(
                DryRun=False,
                DestinationCidrBlock='0.0.0.0/0',
                GatewayId=igwid,
                RouteTableId=self.rtb,
            )
            self.response = add_route_to_igw_res
            return add_route_to_igw_res
        except ClientError as err:
            print('Unexpected error occurred while adding route to IGW...')
            return 'IGW Route not added to routing table', err
