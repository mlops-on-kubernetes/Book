#!/bin/bash
set -e -o pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)

# Deploy the base cluster with prerequisites like ArgoCD and Ingress-nginx
${REPO_ROOT}/terraform/mgmt-cluster/install.sh

# Set the DNS_HOSTNAME to be checked
export DNS_HOSTNAME=$(kubectl get service  ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Replace dns with the value of DNS_HOSTNAME
sed -e "s/INGRESS_DNS/${DNS_HOSTNAME}/g" ${REPO_ROOT}/setups/default-config.yaml > ${REPO_ROOT}/setups/config.yaml

# Deploy the apps

${REPO_ROOT}/setups/install.sh

echo "ArgoCD URL is: https://$DNS_HOSTNAME/argocd"

echo "GITEA URL is: https://$DNS_HOSTNAME/gitea"

echo "Keycloak URL is: https://$DNS_HOSTNAME/keycloak"

echo "Backstage URL is: https://$DNS_HOSTNAME/"

echo "ArgoWorkflows URL is: https://$DNS_HOSTNAME/argo-workflows"

