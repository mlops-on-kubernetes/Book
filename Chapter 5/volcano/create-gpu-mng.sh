# get one of the nodes in the cluster

CLUSTER_NAME=machine-learning

AWS_ACCOUNT_NUM=$(aws sts get-caller-identity --query "Account" --output text)
AWS_REGION=$(aws configure get region)

NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')


INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=private-dns-name,Values=$NODE_NAME" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

echo $NODE_NAME\'s instance id is: $INSTANCE_ID

PROFILE_ARN=$(aws ec2 describe-instances \
	--instance-ids $INSTANCE_ID \
       	--query 'Reservations[].Instances[].IamInstanceProfile.Arn'\
       	--output text)

PROFILE_NAME=$(echo $PROFILE_ARN | sed 's/.*instance-profile\///')

echo instance_profile=$PROFILE_NAME

NODE_ROLE=$(aws iam get-instance-profile --instance-profile-name $PROFILE_NAME --query 'InstanceProfile.Roles[0].RoleName' --output text)
NODE_ROLE="arn:aws:iam::${AWS_ACCOUNT_NUM}:role/${NODE_ROLE}"
echo $NODE_ROLE

SUBNET=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[].Instances[].SubnetId' \
  --output text)

echo subnet=$SUBNET

K8S_VERSION=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.version" --output text)
GPU_AMI=$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2023/x86_64/standard/recommended/image_id \
        --region $AWS_REGION --query "Parameter.Value" --output text)

echo $GPU_AMI

GPU_NODEGROUP_NAME=gpu_nodes

aws eks create-nodegroup \
  --cluster-name machine-learning \
  --subnet $SUBNET \
  --node-role $NODE_ROLE \
  --nodegroup-name $GPU_NODEGROUP_NAME \
  --instance-types 'g4dn.xlarge' \
  --disk-size 100 \
  --scaling-config minSize=2,maxSize=2,desiredSize=2 \
  --ami-type "AL2_x86_64_GPU"
  
