#!/bin/bash

file=./vpc_parameter.txt
if [ -f "$file" ] ; then
    rm $file
fi

# Try to source naming file if exists
NAMING="./NAMING_CONF"
if [ -f $NAMINE ] ; then
    source $NAMING
fi

function create_vpc_and_igw(){
    # Create IGW
    echo "Creating Internet Gateway ..."
    IGWID=$(aws ec2 create-internet-gateway | grep "InternetGatewayId" | awk -F "\"" '{ print $4}')
    # Create VPC
    echo "Creating VPC ..."
    VPCID=$(aws ec2 create-vpc --cidr-block 192.168.0.0/16 | grep "VpcId" | awk -F "\"" '{ print $4}')
    # Attach VPC and IGW
    echo "Attaching IGW to VPC ..."
    aws ec2 attach-internet-gateway --internet-gateway-id $IGWID --vpc-id $VPCID &> /dev/null
    echo "Setting the iptable rule ..."
    # Get the associatd ip-table of the vpc
    VPC_IPTB_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPCID" | grep "RouteTableId" | tail -n 1 | awk -F "\"" '{print $4}')
    # Create the route outing rule in the table
    aws ec2 create-route --route-table-id $VPC_IPTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGWID  &> /dev/null
    echo "VPC settings ... completed"
}

function create_subnets(){
    # Create subnet
    echo "Creating subnets ... (Tokyo)"
    SUBNET_ID_1=$(aws ec2 create-subnet --vpc-id $VPCID --cidr-block 192.168.2.0/24 --availability-zone-id apne1-az1 | grep "SubnetId" | awk -F "\"" '{ print $4}')
    SUBNET_ID_2=$(aws ec2 create-subnet --vpc-id $VPCID --cidr-block 192.168.1.0/24 --availability-zone-id apne1-az2 | grep "SubnetId" | awk -F "\"" '{ print $4}')
    SUBNET_ID_3=$(aws ec2 create-subnet --vpc-id $VPCID --cidr-block 192.168.0.0/24 --availability-zone-id apne1-az4 | grep "SubnetId" | awk -F "\"" '{ print $4}')

    echo "SUBNET_ID_1=\"${SUBNET_ID_1}\"" >> vpc_parameter.txt
    echo "SUBNET_ID_2=\"${SUBNET_ID_2}\"" >> vpc_parameter.txt
    echo "SUBNET_ID_3=\"${SUBNET_ID_3}\"" >> vpc_parameter.txt
    echo "Creating subnets ... (Tokyo) ... Done"

    # Enable auto-assign public IPv4 address
    echo "Allowing auto-assign IP ..."
    aws ec2 modify-subnet-attribute --map-public-ip-on-launch --subnet-id $SUBNET_ID_1 &> /dev/null
    aws ec2 modify-subnet-attribute --map-public-ip-on-launch --subnet-id $SUBNET_ID_2 &> /dev/null
    aws ec2 modify-subnet-attribute --map-public-ip-on-launch --subnet-id $SUBNET_ID_3 &> /dev/null
    echo "Allowing auto-assign IP ... Done"

    echo "Creating Security Group ..."
    SG_ID=$(aws ec2 create-security-group --group-name $SG_NAME --vpc-id $VPCID --description "Security Group for EKS" | grep "GroupId" | awk -F "\"" '{ print $4}')
    echo "Creating Security Group ingress rule ..."
    aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol -1 --port -1 --cidr 0.0.0.0/0 &> /dev/null
    echo "SG_ID=\"${SG_ID}\"" >> vpc_parameter.txt
    CLUSTER_ROLE_ARN=$(aws iam get-role --role-name $CLUSTER_ROLE_NAME | grep "Arn"| awk -F "\"" '{ print $4}')
    echo "Creating Security Group ... Done"
}

function create_cluster(){
    aws eks create-cluster --region ap-northeast-1 \
        --name $CLUSTER_NAME \
        --kubernetes-version 1.17 \
        --role-arn $CLUSTER_ROLE_ARN \
        --resources-vpc-config subnetIds=$SUBNET_ID_1,$SUBNET_ID_2,$SUBNET_ID_3,securityGroupIds=$SG_ID
    echo "Creating EKS Cluster ..."
}

create_vpc_and_igw
create_subnets
create_cluster
