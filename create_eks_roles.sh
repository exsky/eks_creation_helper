#!/bin/bash

CLUSTER_ROLE_NAME='<the-eks-cluster-role>'
NODE_ROLE_NAME='<the-ng-role>'

# Attach AmazonEKSClusterPolicy to Cluster Role
aws iam attach-role-policy --role-name $CLUSTER_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy &> /dev/null

# Attach AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy,
# AmazonEC2ContainerRegistryReadOnly to Nodegroup Role
aws iam attach-role-policy --role-name $NODE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy &> /dev/null
aws iam attach-role-policy --role-name $NODE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy &> /dev/null
aws iam attach-role-policy --role-name $NODE_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly &> /dev/null
