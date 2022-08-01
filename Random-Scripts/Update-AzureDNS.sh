#! /bin/bash

# Define vars
AZ_APP_ID='' # ID of custom app used as Service Principal
AZ_APP_CLIENT_SECRET='' # Generated client secret for the app
TENANT_ID='' # Azure Tenant ID
SUBSCRIPTION_ID='' # Subscription ID that contains Azure DNS
RESOURCE_GROUP='' # Resource Group that Azure DNS is in
DNS_ZONE='' # DNS zone containing records in scope
RECORD_TYPE='' # DNS Record Type to
RECORD_NAME='' # Name of record to create/update

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me)

# Get Bearer Token
TOKEN=$(curl -s -X POST -d "grant_type=client_credentials&client_id=${AZ_APP_ID}&client_secret=${AZ_APP_CLIENT_SECRET}&resource=https%3A%2F%2Fmanagement.azure.com%2F" https://login.microsoftonline.com/${TENANT_ID}/oauth2/token | jq '.access_token'| tr -d '"')

# Get root domain A Record IP in Azure DNS
CURRENT_IP=$(curl -s https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/dnsZones/${DNS_ZONE}/${RECORD_TYPE}/${RECORD_NAME}?api-version=2018-05-01 -H "Authorization: Bearer ${TOKEN}" | jq '.properties.ARecords | .[] | .ipv4Address' | tr -d '"')

# Only update the Azure DNS if the current WAN IP is different to the value of the DNS A record
if [ "${GATEWAY}" != "${CURRENT_IP}" ]; then
    curl -s -X PATCH https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/dnsZones/${DNS_ZONE}/${RECORD_TYPE}/${RECORD_NAME}?api-version=2018-05-01 \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TOKEN}" \
    --data-binary @- << EOF
    {
        "properties": {
            "ARecords": [
                {
                    "ipv4Address": "${PUBLIC_IP}"
                }
            ],
        }
    }
EOF
else
    exit
fi