#!/bin/bash
set -e -o pipefail
REPO_ROOT=$(git rev-parse --show-toplevel)
SUB_LEVEL="Chapter 8"

source ${REPO_ROOT}/${SUB_LEVEL}/setups/utils.sh

echo -e "${GREEN}Installing with the following options: ${NC}"
echo -e "${GREEN}----------------------------------------------------${NC}"
yq '... comments=""' ${REPO_ROOT}/${SUB_LEVEL}/setups/config.yaml
echo -e "${GREEN}----------------------------------------------------${NC}"
echo -e "${PURPLE}\nTargets:${NC}"
echo "Kubernetes cluster: $(kubectl config current-context)"
echo "AWS profile (if set): ${AWS_PROFILE}"
echo "AWS account number: $(aws sts get-caller-identity --query "Account" --output text)"

export GITHUB_URL=$(yq '.repo_url' ${REPO_ROOT}/${SUB_LEVEL}/setups/config.yaml)



# The rest of the steps are defined as a Terraform module. Parse the config to JSON and use it as the Terraform variable file. This is done because JSON doesn't allow you to easily place comments.
cd "${REPO_ROOT}/${SUB_LEVEL}/terraform/"
yq -o json '.'  ${REPO_ROOT}/${SUB_LEVEL}/setups/config.yaml > terraform.tfvars.json
terraform init -upgrade
terraform apply -auto-approve
