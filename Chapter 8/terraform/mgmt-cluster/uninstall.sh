#!/bin/bash
set -e -o pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
#source ${REPO_ROOT}/setups/utils.sh

echo -e "${PURPLE}\nTargets:${NC}"
echo "Kubernetes cluster: $(kubectl config current-context)"
echo "AWS profile (if set): ${AWS_PROFILE}"
echo "AWS account number: $(aws sts get-caller-identity --query "Account" --output text)"

echo -e "${RED}\nAre you sure you want to continue?${NC}"
read -p '(yes/no): ' response
if [[ ! "$response" =~ ^[Yy][Ee][Ss]$ ]]; then
  echo 'exiting.'
  exit 0
fi

SETUP_DIR="${REPO_ROOT}/setups"

cd "${SETUP_DIR}/argocd/"
./uninstall.sh
cd -

cd "${REPO_ROOT}/terraform/mgmt-cluster"

kubectl delete -f ./karpenter.yaml || true

terraform destroy
