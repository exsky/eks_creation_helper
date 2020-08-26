# EKS creation helper
This is a script repository for create EKS in easy way.

## Simple Steps
#### 1. Edit the NAMING_CONF
```
vim NAMING_CONF
```
對於下方預設內容進行修改
```
SSH_KEY_PAIR='ENTER-YOUR-SSH-KEY-PAIR_NAME-HERE'
CLUSTER_ROLE_NAME='my-eks-cluster-role'
NODE_ROLE_NAME='my-eks-ng-role'
SG_NAME='my-eks-security-group'
CLUSTER_NAME='my-eks-cluster'
NG_NAME='my-micro-ng3'
```
1. 先修改 `NAMING_CONF` 中的內容，其中 `SSH_KEY_PAIR` 要調整成存放在 AWS 中的 Key Pair，若您不清楚如何設定，請參考[**官方文件**](https://docs.aws.amazon.com/zh_tw/AWSEC2/latest/UserGuide/ec2-key-pairs.html)，進行金鑰對的設定。
2. `CLUSTER_ROLE_NAME` 為叢集角色名稱，可自行修改成喜歡的名字。
3. `NODE_ROLE_NAME` 為節點角色名稱，可自行修改成喜歡的名字。
4. `SG_NAME` 為新建的 Security Group 名稱，可自行修改成喜歡的名字。
5. `CLUSTER_NAME` 為新建的叢集名稱，可自行修改成喜歡的名字。
6. `NG_NAME` 為新建的節點群組名稱，可自行修改成喜歡的名字。

#### 2. Create Roles and Policies
```
./create_eks_roles.sh
```
#### 3. Create EKS Cluster
```
./create_eks_cluster.sh
```
#### 4. Create EKS Node Group
```
./create_eks_nodegroup.sh
```

