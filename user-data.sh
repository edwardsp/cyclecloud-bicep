#!/bin/bash

# install instructions from here: https://learn.microsoft.com/en-us/azure/cyclecloud/how-to/install-manual?view=cyclecloud-8#installing-on-debian-or-ubuntu
apt update
apt -y install wget gnupg2
wget -qO - https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
echo 'deb https://packages.microsoft.com/repos/cyclecloud bionic main' > /etc/apt/sources.list.d/cyclecloud.list
apt update
apt -y install cyclecloud8

# wait for cycle to start
/opt/cycle_server/cycle_server await_startup

cat <<EOF >/opt/cycle_server/config/data/cyclecloud_account.json
[
    {
        "AdType": "Application.Setting",
        "Name": "cycleserver.installation.initial_user",
        "Value": "CYCLECLOUD_ADMIN_NAME"
    },
    {
        "AdType": "AuthenticatedUser",
        "Name": "CYCLECLOUD_ADMIN_NAME",
        "RawPassword": "CYCLECLOUD_ADMIN_PASSWORD",
        "Superuser": true
    },
    {
        "AdType": "Credential",
        "CredentialType": "PublicKey",
        "Name": "CYCLECLOUD_ADMIN_NAME/public",
        "PublicKey": "CYCLECLOUD_ADMIN_PUBLIC_KEY"
    },
    {
        "AdType": "Application.Setting",
        "Name": "cycleserver.installation.complete",
        "Value": true
    }
]
EOF

cat <<EOF >/opt/cycle_server/azure_subscription.json
{
    "Environment": "public",
    "AzureRMUseManagedIdentity": true,
    "AzureResourceGroup": "CYCLECLOUD_RESOURCE_GROUP",
    "AzureRMApplicationId": " ",
    "AzureRMApplicationSecret": " ",
    "AzureRMSubscriptionId": "AZURE_SUBSCRIPTION_ID",
    "AzureRMTenantId": " AZURE_TENANT_ID",
    "DefaultAccount": true,
    "Location": "CYCLECLOUD_LOCATION",
    "Name": "CYCLECLOUD_SUBSCRIPTION_NAME",
    "Provider": "azure",
    "ProviderId": "fd6abe95-c55e-44c8-9085-68002a27c1bb",
    "RMStorageAccount": "CYCLECLOUD_STORAGE_ACCOUNT",
    "RMStorageContainer": "CYCLECLOUD_STORAGE_CONTAINER",
    "AcceptMarketplaceTerms": true
}
EOF

# needed to install CycleCloud CLI
apt install -y unzip python3-venv
unzip /opt/cycle_server/tools/cyclecloud-cli.zip -d /tmp
python3 /tmp/cyclecloud-cli-installer/install.py -y --installdir /home/CYCLECLOUD_ADMIN_NAME/.cycle --system
# Must run as user or CycleCloud will attempt to install in /root/.cycle
runuser -l CYCLECLOUD_ADMIN_NAME -c '/usr/local/bin/cyclecloud initialize --loglevel=debug --batch --url=http://localhost:8080 --verify-ssl=false --username=CYCLECLOUD_ADMIN_NAME --password="CYCLECLOUD_ADMIN_PASSWORD"'
runuser -l CYCLECLOUD_ADMIN_NAME -c '/usr/local/bin/cyclecloud account create -f /opt/cycle_server/azure_subscription.json'

# now use the cli to set up queues
# ...
