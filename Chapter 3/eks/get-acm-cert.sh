#!/bin/bash
# 
# Thanks to Andrew Odri for the gist shared at https://gist.github.com/andrewodri/1d3c25b01f2b7b307f4b7b538ef36fff
# Usage ./get-acm-cert.sh
# 
#
CERT_ARN=$(aws acm request-certificate \
  --domain-name "$1" \
  --subject-alternative-names "*.$1" \
  --validation-method DNS \
  --query CertificateArn \
  --output text)

while [[ -z "$CNAME_NAME" ]]; do

  CNAME_NAME="$(aws acm describe-certificate \
    --certificate-arn "${CERT_ARN}" \
    --query "Certificate.DomainValidationOptions[?DomainName=='$1'].ResourceRecord.Name" \
    --output text)"

  if [[ -z "$CNAME_NAME" ]]; then 
    echo "CNAME_NAME is empty. Retrying in 5 seconds..."
    sleep 5
  fi

done

CNAME_VALUE="$(aws acm describe-certificate \
  --certificate-arn "${CERT_ARN}" \
  --query "Certificate.DomainValidationOptions[?DomainName=='$1'].ResourceRecord.Value" \
  --output text)"

HOSTED_ZONE_ID="$(aws route53 list-hosted-zones-by-name \
  --dns-name "$1" \
  --query "HostedZones[?Name=='$1.'].Id" \
  --output text)"

HOSTED_ZONE_ID=${HOSTED_ZONE_ID##*/}

CHANGE_BATCH=$(cat <<EOM
  {
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "${CNAME_NAME}",
          "Type": "CNAME",
          "TTL": 300,
          "ResourceRecords": [
            {
              "Value": "${CNAME_VALUE}"
            }
          ]
        }
      }
    ]
  }
EOM
)


CHANGE_BATCH_REQUEST_ID=$(aws route53 change-resource-record-sets \
  --hosted-zone-id "${HOSTED_ZONE_ID}" \
  --change-batch "${CHANGE_BATCH}" \
  --query "ChangeInfo.Id" \
  --output text)

echo "[ACM]          Waiting for certificate to be validated. This can take a few minutes..."
aws acm wait certificate-validated \
  --certificate-arn "${CERT_ARN}"

ACM_CERTIFICATE_STATUS="$(aws acm describe-certificate \
  --certificate-arn "${CERT_ARN}" \
  --query "Certificate.Status" \
  --output text)"

echo $ACM_CERTIFICATE_STATUS
echo $CERT_ARN 
