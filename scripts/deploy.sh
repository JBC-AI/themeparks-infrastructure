#!/bin/bash

# Setting -e and -v as pert https://docs.travis-ci.com/user/customizing-the-build/#Implementing-Complex-Build-Steps
# -e: immediately exit if any command has a non-zero exit status
# -v: print all lines in the script before executing them
# -o: prevents errors in a pipeline from being masked
set -euo pipefail

# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)
IFS=$'\n\t'

aksName=$(./scripts/deploy-rg.sh -u $servicePrincipalId -s $servicePrincipalSecret -t $tenant -g $resourceGroupName -l $resourceGroupLocation -d $templateFilePath -p $parametersFilePath -q properties.outputs.aksName.value aksAgentAdminUsername=$aksAgentAdminUsername aksAgentSshRSAPublicKey="$aksAgentSshRSAPublicKey" aksServicePrincipalClientId=$aksServicePrincipalClientId aksServicePrincipalClientSecret=$aksServicePrincipalClientSecret microsoftAppId=$microsoftAppId)

./scripts/install-helm.sh -u $servicePrincipalId -s $servicePrincipalSecret -t $tenant -g $resourceGroupName -c $aksName