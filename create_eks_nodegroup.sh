#!/bin/bash

# Try to source naming file if exists
NAMING="./NAMING_CONF"
if [ -f $NAMINE ] ; then
    source $NAMING
fi

file="./vpc_parameter.txt"
if [ -f $file ] ; then
    source $file
    echo "The node(s) will using the subnets ..."
    echo "$SUBNET_ID_1"
    echo "$SUBNET_ID_2"
    echo "$SUBNET_ID_3"
else
    echo "No subnets configration detected !!"
fi

#NG_ROLE='<nodegroup-role>'
echo "Fetching the node group arn ..."
NG_ROLE_ARN=$(aws iam get-role --role-name $NODE_ROLE_NAME | grep "Arn"| awk -F "\"" '{ print $4}')

function detecting_cluster_status(){
    # Detect current cluster status
    STATUS=$(aws eks describe-cluster --name $CLUSTER_NAME | grep status | awk -F "\"" '{ print $4}')
    if [ $STATUS = 'ACTIVE' ] ; then
        # echo "The status of EKS cluster is ACTIVE ..."
        echo 0
    else
        # echo "The status of EKS cluster is NOT ACTIVE ..."
        echo 1
    fi
}

function create_nodegroup(){
    aws eks create-nodegroup \
        --cluster-name $CLUSTER_NAME \
        --nodegroup-name $NG_NAME \
        --node-role $NG_ROLE_ARN \
        --subnets "$SUBNET_ID_1" "$SUBNET_ID_2" "$SUBNET_ID_3" \
        --scaling-config minSize=1,maxSize=3,desiredSize=1 \
        --ami-type AL2_x86_64 \
        --instance-types t3.small \
        --remote-access ec2SshKey=$SSH_KEY_PAIR,sourceSecurityGroups=$SG_ID
    echo "Creating Node Group ..."
}

CLUSTER_STATUS=$(detecting_cluster_status)
if [ $CLUSTER_STATUS = 0 ]; then
    echo "Creating Node Group ..."
    create_nodegroup
else
    echo "The cluster is not ready ..."
fi
