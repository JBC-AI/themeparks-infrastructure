#!/bin/bash

# Setting -e and -v as pert https://docs.travis-ci.com/user/customizing-the-build/#Implementing-Complex-Build-Steps
# -e: immediately exit if any command has a non-zero exit status
# -v: print all lines in the script before executing them
# -o: prevents errors in a pipeline from being masked
set -euo pipefail

# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)
IFS=$'\n\t'

usage() { echo "Usage: $0 -u <servicePrincipalId> -s <servicePrincipalSecret> -t <tenant> -g <resourceGroupName> -l <resourceGroupLocation> -d <templateFilePath> -p <parametersFilePath>" 1>&2; exit 1; }

declare servicePrincipalId=""
declare servicePrincipalSecret=""
declare tenant=""
declare resourceGroupName=""
declare resourceGroupLocation=""
declare templateFilePath=""
declare parametersFilePath=""

# Initialize parameters specified from command line
while getopts ":u:s:t:g:l:d:p:" arg; do
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
		l)
			resourceGroupLocation=${OPTARG}
			;;
        d)
			templateFilePath=${OPTARG}
			;;
        p)
			parametersFilePath=${OPTARG}
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

if [[ -z "$resourceGroupLocation" ]]; then
	echo "ResourceGroupLocation:"
	read resourceGroupLocation
	[[ "${resourceGroupLocation:?}" ]]
fi

if [[ -z "$templateFilePath" ]]; then
	echo "TemplateFilePath:"
	read templateFilePath
	[[ "${templateFilePath:?}" ]]
fi

if [[ -z "$parametersFilePath" ]]; then
	echo "ParametersFilePath:"
	read parametersFilePath
	[[ "${parametersFilePath:?}" ]]
fi

# Ensuring files exist.
if [ ! -f "$templateFilePath" ] || [ -z "$parametersFilePath" ]; then
	echo "Either $templateFilePath or $parametersFilePath cannot be found"
	exit 1
fi

# Follow the steps here to create a Service Principal: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal
az login --service-principal -u $servicePrincipalId -p $servicePrincipalSecret --tenant $tenant

# Check for existing RG
exists=$(az group exists --name $resourceGroupName)

if [ $exists = false ]; then
	echo "Resource group with name" $resourceGroupName "could not be found. Creating new resource group.."
	(
		set -x
		az group create --name $resourceGroupName --location $resourceGroupLocation 1> /dev/null
	)
else
	echo "Using existing resource group..."
fi

# Validate deployment
echo "Validating deployment..."
(
	set -x

    if [ $1 ]; then
        # Additional parameters specified, pass to deployment.
        az group deployment validate --resource-group $resourceGroupName --template-file $templateFilePath --parameters @$parametersFilePath --parameters $@
    else        
        az group deployment validate --resource-group $resourceGroupName --template-file $templateFilePath --parameters @$parametersFilePath 
    fi	
)

if [ $?  == 0 ];
 then
	echo "Template has been successfully validated"
fi