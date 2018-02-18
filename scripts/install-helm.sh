#!/bin/bash

# Setting -e and -v as pert https://docs.travis-ci.com/user/customizing-the-build/#Implementing-Complex-Build-Steps
# -e: immediately exit if any command has a non-zero exit status
# -v: print all lines in the script before executing them
# -o: prevents errors in a pipeline from being masked
set -euo pipefail

# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)
IFS=$'\n\t'

usage() { echo "Usage: $0 -u <servicePrincipalId> -s <servicePrincipalSecret> -t <tenant> -g <resourceGroupName> -c <clusterName>" 1>&2; exit 1; }

declare servicePrincipalId=""
declare servicePrincipalSecret=""
declare tenant=""
declare resourceGroupName=""
declare clusterName=""

# Initialize parameters specified from command line
while getopts ":u:s:t:g:c:" arg; do
	case "${arg}" in		
		u)
			servicePrincipalId=${OPTARG}
			;;
        s)
			servicePrincipalSecret=${OPTARG}
			;;
        t)
			tenant=${OPTARG}
			;;
        g)
			resourceGroupName=${OPTARG}
			;;
		c)
			clusterName=${OPTARG}
			;;
		esac
done
shift $((OPTIND-1))

# Prompt for parameters is some required parameters are missing
if [[ -z "$servicePrincipalId" ]]; then
	echo "ServicePrincipalId:"
	read servicePrincipalId
	[[ "${servicePrincipalId:?}" ]]
fi

if [[ -z "$servicePrincipalSecret" ]]; then
	echo "ServicePrincipalSecret:"
	read servicePrincipalSecret
	[[ "${servicePrincipalSecret:?}" ]]
fi

if [[ -z "$tenant" ]]; then
	echo "Tenant:"
	read tenant
	[[ "${tenant:?}" ]]
fi

if [[ -z "$resourceGroupName" ]]; then
	echo "ResourceGroupName:"
	read resourceGroupName
	[[ "${resourceGroupName:?}" ]]
fi

if [[ -z "$clusterName" ]]; then
	echo "ClusterName:"
	read clusterName
	[[ "${clusterName:?}" ]]
fi

# Follow the steps here to create a Service Principal: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal
az login --service-principal -u $servicePrincipalId -p $servicePrincipalSecret --tenant $tenant 1> /dev/null

echo "Getting credentials for cluster..."
az aks get-credentials --name $clusterName --resource-group $resourceGroupName

echo "Setting up Helm..."
helm init --override storage=secret