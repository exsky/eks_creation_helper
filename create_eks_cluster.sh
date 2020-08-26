#!/bin/bash

file=./vpc_parameter.txt
if [ -f $file ] ; then
    rm $file
fi

CLUSTER_ROLE_NAME='<my-eks-cluster-role>'
NODE_ROLE_NAME='<my-ng-role>'
SG_NAME='<my-sg>'
CLUSTER_NAME='<my-eks-cluster>'
SSH_KEY_PAIR='<YOURKEY-PAIR-NAME>'

# Create IGW
IGWID=$(aws ec2 create-internet-gateway | grep "InternetGatewayId" | awk -F "\"" '{ print $4}')
# Create VPC
VPCID=$(aws ec2 create-vpc --cidr-block 192.168.0.0/16 | grep "VpcId" | awk -F "\"" '{ print $4}')
# Attach VPC and IGW
aws ec2 attach-internet-gateway --internet-gateway-id $IGWID --vpc-id $VPCID &> /dev/null
# Get the associatd ip-table of the vpc
VPC_IPTB_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPCID" | grep "RouteTableId" | tail -n 1 | awk -F "\"" '{print $4}')
# Create the route outing rule in the table
aws ec2 create-route --route-table-id $VPC_IPTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGWID  &> /dev/null


# Create subnet
SUBNET_ID_1=$(aws ec2 create-subnet --vpc-id $VPCID --cidr-block 192.168.2.0/24 --availability-zone-id apne1-az1 | grep "SubnetId" | awk -F "\"" '{ print $4}')
SUBNET_ID_2=$(aws ec2 create-subnet --vpc-id $VPCID --cidr-block 192.168.1.0/24 --availability-zone-id apne1-az2 | grep "SubnetId" | awk -F "\"" '{ print $4}')
SUBNET_ID_3=$(aws ec2 create-subnet --vpc-id $VPCID --cidr-block 192.168.0.0/24 --availability-zone-id apne1-az4 | grep "SubnetId" | awk -F "\"" '{ print $4}')

echo "SUBNET_ID_1=\"${SUBNET_ID_1}\"" >> vpc_parameter.txt
echo "SUBNET_ID_2=\"${SUBNET_ID_2}\"" >> vpc_parameter.txt
echo "SUBNET_ID_3=\"${SUBNET_ID_3}\"" >> vpc_parameter.txt

# Enable auto-assign public IPv4 address
aws ec2 modify-subnet-attribute --map-public-ip-on-launch --subnet-id $SUBNET_ID_1 &> /dev/null
aws ec2 modify-subnet-attribute --map-public-ip-on-launch --subnet-id $SUBNET_ID_2 &> /dev/null
aws ec2 modify-subnet-attribute --map-public-ip-on-launch --subnet-id $SUBNET_ID_3 &> /dev/null

SG_ID=$(aws ec2 create-security-group --group-name $SG_NAME --vpc-id $VPCID --description "Security Group for EKS" | grep "GroupId" | awk -F "\"" '{ print $4}')
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol -1 --port -1 --cidr 0.0.0.0/0 &> /dev/null
echo "SG_ID=\"${SG_ID}\"" >> vpc_parameter.txt

CLUSTER_ROLE_ARN=$(aws iam get-role --role-name $CLUSTER_ROLE_NAME | grep "Arn"| awk -F "\"" '{ print $4}')

aws eks create-cluster --region ap-northeast-1 \
    --name $CLUSTER_NAME \
    --kubernetes-version 1.17 \
    --role-arn $CLUSTER_ROLE_ARN \
    --resources-vpc-config subnetIds=$SUBNET_ID_1,$SUBNET_ID_2,$SUBNET_ID_3,securityGroupIds=$SG_ID
