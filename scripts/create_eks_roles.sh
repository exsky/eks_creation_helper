#!/bin/bash

# Try to source naming file if exists
NAMING="./NAMING_CONF"
if [ -f $NAMINE ] ; then
    source $NAMING
fi

if [ -z "$CLUSTER_ROLE_NAME" ] ; then
      echo "\$CLUSTER_ROLE_NAME is empty"
      echo $CLUSTER_ROLE_NAME
      CLUSTER_ROLE_NAME='my-eks-cluster-role'
fi
if [ -z "$NODE_ROLE_NAME" ]
then
      echo "\$NODE_ROLE_NAME is empty"
      echo $NODE_ROLE_NAME
      NODE_ROLE_NAME='my-eks-ng-role'
fi

function create_roles(){
    # create node role and policies
    # Ref: https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html
    echo "Creating EKS Role ..."
    aws iam create-role --role-name $CLUSTER_ROLE_NAME --assume-role-policy-document file://assume_eks.json &> /dev/null
    echo "Creating EKS Role ... completed"
    # Ref: https://docs.aws.amazon.com/zh_tw/eks/latest/userguide/worker_node_IAM_role.html
    echo "Creating Node Group Role ..."
    aws iam create-role --role-name $NODE_ROLE_NAME --assume-role-policy-document file://assume_node.json &> /dev/null
    echo "Creating Node Group Role ... completed"
}

function attach_policies(){
    # Attach AmazonEKSClusterPolicy to Cluster Role
    echo "Attaching AmazonEKSClusterPolicy to EKS Role ..."
    aws iam attach-role-policy --role-name $CLUSTER_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy &> /dev/null
    echo "Attaching AmazonEKSClusterPolicy to EKS Role ... completed"

    # Attach AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy and AmazonEC2ContainerRegistryReadOnly to Nodegroup Role
    echo "Attaching AmazonEKSWorkerNodePolicy to Node Group Role ..."
    aws iam attach-role-policy --role-name $NODE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy &> /dev/null
    echo "Attaching AmazonEKS_CNI_Policy to Node Group Role ..."
    aws iam attach-role-policy --role-name $NODE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy &> /dev/null
    echo "Attaching AmazonEC2ContainerRegistryReadOnly to Node Group Role ..."
    aws iam attach-role-policy --role-name $NODE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly &> /dev/null
    echo "Attaching Policies to Node Group Role ... completed"
}

create_roles
attach_policies

