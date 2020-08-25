#!/bin/bash

CLUSTER_ROLE_NAME='<my-eks-cluster-role>'
NODE_ROLE_NAME='<my-ng-role>'
SG_NAME='<my-sg>'
CLUSTER_NAME='<my-eks-cluster>'
SSH_KEY_PAIR='<YOURKEY-PAIR-NAME>'

CLUSTER_ROLEID=$( aws iam create-role --role-name $CLUSTER_ROLE_NAME --assume-role-policy-document file://assume_eks.json | grep "RoleId" | awk -F "\"" '{ print $4}' )
NODEGROUP_ROLEID=$( aws iam create-role --role-name $NODE_ROLE_NAME --assume-role-policy-document file://assume_node.json | grep "RoleId" | awk -F "\"" '{ print $4}' )

# Attach AmazonEKSClusterPolicy to Cluster Role
aws iam attach-role-policy --role-name $CLUSTER_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# Attach AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy,
# AmazonEC2ContainerRegistryReadOnly to Nodegroup Role
aws iam attach-role-policy --role-name $NODE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam attach-role-policy --role-name $NODE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
aws iam attach-role-policy --role-name $NODE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# Create IGW
IGWID=$(aws ec2 create-internet-gateway | grep "InternetGatewayId" | awk -F "\"" '{ print $4}')
# Create VPC
VPCID=$(aws ec2 create-vpc --cidr-block 192.168.0.0/16 | grep "VpcId" | awk -F "\"" '{ print $4}')
# Attach VPC and IGW
aws ec2 attach-internet-gateway --internet-gateway-id $IGWID --vpc-id $VPCID

# Create subnet
SUBNET_ID_1=$(aws ec2 create-subnet --vpc-id $VPCID --cidr-block 192.168.2.0/24 --availability-zone-id apne1-az1 | grep "SubnetId" | awk -F "\"" '{ print $4}')
SUBNET_ID_2=$(aws ec2 create-subnet --vpc-id $VPCID --cidr-block 192.168.1.0/24 --availability-zone-id apne1-az2 | grep "SubnetId" | awk -F "\"" '{ print $4}')
SUBNET_ID_3=$(aws ec2 create-subnet --vpc-id $VPCID --cidr-block 192.168.0.0/24 --availability-zone-id apne1-az4 | grep "SubnetId" | awk -F "\"" '{ print $4}')

echo "SUBNET_ID_1=\"${SUBNET_ID_1}\"" >> vpc_parameter.txt
echo "SUBNET_ID_2=\"${SUBNET_ID_2}\"" >> vpc_parameter.txt
echo "SUBNET_ID_3=\"${SUBNET_ID_3}\"" >> vpc_parameter.txt

# Enable auto-assign public IPv4 address
aws ec2 modify-subnet-attribute --map-public-ip-on-launch --subnet-id $SUBNET_ID_1
aws ec2 modify-subnet-attribute --map-public-ip-on-launch --subnet-id $SUBNET_ID_2
aws ec2 modify-subnet-attribute --map-public-ip-on-launch --subnet-id $SUBNET_ID_3

SG_ID=$(aws ec2 create-security-group --group-name $SG_NAME --vpc-id $VPCID --description "Security Group for EKS" | grep "GroupId" | awk -F "\"" '{ print $4}')
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol -1 --port -1 --cidr 0.0.0.0/0
echo "SG_ID=\"${SG_ID}\"" >> vpc_parameter.txt

CLUSTER_ROLE_ARN=$(aws iam get-role --role-name $CLUSTER_ROLE_NAME | grep "Arn"| awk -F "\"" '{ print $4}')

aws eks create-cluster --region ap-northeast-1 \
    --name $CLUSTER_NAME \
    --kubernetes-version 1.17 \
    --role-arn $CLUSTER_ROLE_ARN \
    --resources-vpc-config subnetIds=$SUBNET_ID_1,$SUBNET_ID_2,$SUBNET_ID_3,securityGroupIds=$SG_ID
