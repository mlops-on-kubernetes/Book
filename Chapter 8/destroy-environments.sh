
#!/bin/bash
#
# Copyright 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

#title           destroy-environments.sh
#description     This script deletes all terraform EKS clusters and prerequisites
#version         1.0
#==============================================================================

# checking environment variables

if [ -z "${TF_VAR_aws_region}" ]; then
    message="env variable AWS_REGION not set, defaulting to us-west-2"
    echo $message
    export TF_VAR_aws_region="us-west-2"
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
SUB_LEVEL="Chapter 8"

echo "Following environment variables will be used:"
echo "CLUSTER_REGION = "$TF_VAR_aws_region

# Destroy possible resources that may not be cleaned up by terraform

LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers --region $TF_VAR_aws_region --names "modern-engg" --query 'LoadBalancers[*].LoadBalancerArn' --output text) || true

TARGET_GROUP_ARNS=$(aws elbv2 describe-target-groups --region $TF_VAR_aws_region --load-balancer-arn $LOAD_BALANCER_ARN --query 'TargetGroups[*].TargetGroupArn' --output text)

# Split the target group ARNs into an array
read -r -a TARGET_GROUP_ARN_ARRAY <<< "$TARGET_GROUP_ARNS"

# Loop through each target group ARN and delete the target group
for TARGET_GROUP_ARN in "${TARGET_GROUP_ARN_ARRAY[@]}"
do
    echo "Deleting target group: $TARGET_GROUP_ARN"
    aws elbv2 delete-target-group --region $TF_VAR_aws_region --target-group-arn $TARGET_GROUP_ARN || true
done

aws elbv2 delete-load-balancer --region $TF_VAR_aws_region --load-balancer-arn $LOAD_BALANCER_ARN || true

# Destroy bootstrap Bucket, DynamoDB lock table, Amazon Managed Grafana and Amazon Managed Prometheus
#terraform -chdir=bootstrap destroy -auto-approve

# Cleanup the IDP Builder and applications
${REPO_ROOT}/${SUB_LEVEL}/setups/uninstall.sh

# Cleanup the keycloak Secret config if not cleaned
aws secretsmanager delete-secret --secret-id "modern-engg/keycloak/config" --force-delete-without-recovery --region $TF_VAR_aws_region || true

# Cleanup the IDP EKS management cluster and prerequisites
${REPO_ROOT}/${SUB_LEVEL}/terraform/mgmt-cluster/uninstall.sh

rm -rf ${REPO_ROOT}/platform/infra/terraform/.git || true

echo "Terraform execution completed"

# Cleanup Folders
rm -rf terraform-aws-observability-accelerator/

echo "Destroy Complete"
