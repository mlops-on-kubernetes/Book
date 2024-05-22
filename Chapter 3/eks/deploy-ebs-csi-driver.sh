
AWS_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
AWS_REGION=us-west-2
EBS_CSI_DRIVER_ROLE_NAME=ML-AmazonEKS_EBS_CSI_DriverRole
EKS_CLUSTER_NAME=machine-learning

EKS_OIDC=$(aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION} --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f5)

EBS_CSI_DRIVER_TRUST_POLICY=$(cat <<EOM
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT}:oidc-provider/oidc.eks.${AWS_REGION}.amazonaws.com/id/${EKS_OIDC}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.${AWS_REGION}.amazonaws.com/id/${EKS_OIDC}:aud": "sts.amazonaws.com",
          "oidc.eks.${AWS_REGION}.amazonaws.com/id/${EKS_OIDC}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
EOM
)

aws iam create-role --role-name $EBS_CSI_DRIVER_ROLE_NAME --assume-role-policy-document "$EBS_CSI_DRIVER_TRUST_POLICY"

aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --role-name $EBS_CSI_DRIVER_ROLE_NAME

aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --service-account-role-arn arn:aws:iam::${AWS_ACCOUNT}:role/${EBS_CSI_DRIVER_ROLE_NAME} --addon-name aws-ebs-csi-driver

EBS_CONTROLLER_TOLERATION=$(cat <<EOM
 spec:
  template:
    spec:
      tolerations:
      - effect: NoSchedule
        key: "karpenter.sh/controller"
        value: "true"
EOM
)

cat << EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
EOF

# kubectl patch -n kube-system deployment ebs-csi-controller --patch $EBS_CONTROLLER_TOLERATION
