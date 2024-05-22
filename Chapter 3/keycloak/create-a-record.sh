#!/usr/bin/env bash
###
# This script adds an alias A record in Route 53 hosted zone. 
# Usage: create-a-record.sh <domain name (www.example.com)> <host>
###

HOSTED_ZONE_ID="$(aws route53 list-hosted-zones-by-name \
  --dns-name "$1" \
  --query "HostedZones[?Name=='$1.'].Id" \
  --output text)"

HOSTED_ZONE_ID=${HOSTED_ZONE_ID##*/}

NLB_ADDRESS=$(kubectl get service -n kube-system ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

NLB_HOSTED_ZONE=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?DNSName=='${NLB_ADDRESS}'].CanonicalHostedZoneId" \
  --output text)

HOST=$2.$1

CHANGE_BATCH=$(cat <<EOM
  {
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "${HOST}",
          "Type": "A",
          "AliasTarget": {
            "HostedZoneId": "${NLB_HOSTED_ZONE}",
            "DNSName": "${NLB_ADDRESS}",
            "EvaluateTargetHealth": false
          }
        }
      }
    ]
  }
EOM
)

aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch "${CHANGE_BATCH}"
