#!/bin/bash

source vpc_parameter.txt
SSH_KEY_PAIR='<SSH-KEY-PAIR>'
CLUSTER_NAME='<cluster-name>'
NG_ROLE='<nodegroup-role>'
NG_NAME='my-micro-ng3'
NG_ROLE_ARN=$(aws iam get-role --role-name $NG_ROLE | grep "Arn"| awk -F "\"" '{ print $4}')

aws eks create-nodegroup \
    --cluster-name $CLUSTER_NAME \
    --nodegroup-name $NG_NAME \
    --node-role $NG_ROLE_ARN \
    --subnets "$SUBNET_ID_1" "$SUBNET_ID_2" "$SUBNET_ID_3" \
    --scaling-config minSize=1,maxSize=3,desiredSize=1 \
    --ami-type AL2_x86_64 \
    --instance-types t3.micro \
    --remote-access ec2SshKey=$SSH_KEY_PAIR
