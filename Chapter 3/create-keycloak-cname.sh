
HOSTED_ZONE_ID="$(aws route53 list-hosted-zones-by-name \
  --dns-name "$1" \
  --query "HostedZones[?Name=='$1.'].Id" \
  --output text)"

HOSTED_ZONE_ID=${HOSTED_ZONE_ID##*/}

ALB_ADDRESS=$(kubectl -n keycloak get ingress auth-ingress \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

ALB_HOSTED_ZONE=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?DNSName=='${ALB_ADDRESS}'].CanonicalHostedZoneId" \
  --output text)

KEYCLOAK_HOSTNAME=auth.$1

CHANGE_BATCH=$(cat <<EOM
  {
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "${KEYCLOAK_HOSTNAME}",
          "Type": "CNAME",
          "AliasTarget": {
            "HostedZoneId": "${ALB_HOSTED_ZONE}",
            "DNSName": "${ALB_ADDRESS}",
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
