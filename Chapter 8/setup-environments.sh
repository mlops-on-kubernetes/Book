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

#title           create-workshop.sh
#description     This script sets up terraform EKS clusters and prerequisites
#version         1.0
#==============================================================================
set -e -o pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
SUB_LEVEL="Chapter 8"

# Deploy the base cluster with prerequisites like ArgoCD and Ingress-nginx
"${REPO_ROOT}/${SUB_LEVEL}/terraform/mgmt-cluster/install.sh"

# Set the DNS_HOSTNAME to be checked
export DNS_HOSTNAME=$(kubectl get service  ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Replace dns with the value of DNS_HOSTNAME
sed -e "s/INGRESS_DNS/${DNS_HOSTNAME}/g" ${REPO_ROOT}/${SUB_LEVEL}/setups/default-config.yaml > ${REPO_ROOT}/${SUB_LEVEL}/setups/config.yaml

# Deploy the apps

"${REPO_ROOT}/${SUB_LEVEL}/setups/install.sh"

echo "ArgoCD URL is: https://$DNS_HOSTNAME/argocd"

echo "GITEA URL is: https://$DNS_HOSTNAME/gitea"

echo "Keycloak URL is: https://$DNS_HOSTNAME/keycloak"

echo "Backstage URL is: https://$DNS_HOSTNAME/"

echo "ArgoWorkflows URL is: https://$DNS_HOSTNAME/argo-workflows"

