#!/bin/sh
#
# This script will be used in case of running terraform template in the Github workflows, local terraform environment.
# For running on the Terraform Cloud, this script is no longer required.
#

projectRGName="${STORAGE_ACCOUNT_RG_NAME}"
location="${STORAGE_ACCOUNT_LOCATION}"
tfbackendAccountName="${STORAGE_ACCOUNT_NAME}"
tfcontainerName="${STORAGE_CONTAINER_NAME}"

# verify resource group
#=============================================================
resourceGroupCount=$(az group list --query "[?name=='"$projectRGName"']" | jq -r '. | length')
if [[ 0 -eq $resourceGroupCount ]]
then
    az group create --name $projectRGName --location $location --output none
    echo "INFO: resource group for project has been created successfully."
else
    echo "INFO: resource group is exists. Ignore creating!"
fi

# verify storage account
#=============================================================
storageAccountCount=$(az storage account list --query "[?name=='"$tfbackendAccountName"']" | jq -r '. | length')
if [[ 0 -eq $storageAccountCount ]]
then
    az storage account create --name $tfbackendAccountName --resource-group $projectRGName --output none
    echo "INFO: storage account for Terraform backend has been created successfully"
else
    echo "INFO: storage account is exists. Ignore creating!"
fi

# verify backend container
#=============================================================
containerCount=$(az storage container list --account-name $tfbackendAccountName --query "[?name=='"$tfcontainerName"']" | jq -r '. | length')
if [[ 0 -eq $containerCount ]]
then
    az storage container create --name $tfcontainerName --account-name $tfbackendAccountName --output none
    echo "INFO: storage account for Terraform backend has been created successfully"
else
    echo "INFO: container for terraform is exists. Ignore creating!"
fi

echo "INFO: installation has completed, see the log at $(pwd)/install_logs.txt"