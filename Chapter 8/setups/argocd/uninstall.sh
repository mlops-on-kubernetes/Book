#!/bin/bash
set -e -o pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
SUB_LEVEL="Chapter 8"
kustomize build ${REPO_ROOT}/${SUB_LEVEL}/packages/argocd/dev  | kubectl delete -f -

kubectl delete ns argocd || true
