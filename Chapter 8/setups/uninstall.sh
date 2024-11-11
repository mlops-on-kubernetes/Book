#!/bin/bash
set -e -o pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
SUB_LEVEL="Chapter 8"
SETUP_DIR="${REPO_ROOT}/${SUB_LEVEL}/setups"
TF_DIR="${REPO_ROOT}/${SUB_LEVEL}/terraform"

cd "${SETUP_DIR}"

echo -e "${PURPLE}\nTargets:${NC}"
echo "Kubernetes cluster: $(kubectl config current-context)"
echo "AWS profile (if set): ${AWS_PROFILE}"
echo "AWS account number: $(aws sts get-caller-identity --query "Account" --output text)"

cd "${TF_DIR}"
terraform destroy

