#AzureKubernetesService AKS

#Quickstart
#https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough

#start the AzureCloudShell
#--------------------------
#  https://portal.azure.com -> click the > icon at the top right of the screen

#Define Variables
#-----------------
#!/bin/bash
# import variables
# check for variabels
#-----------------------
printf '%s' "Importing variables... "
#TBD: verify ALL variables
. ./00_define_vars.sh

varsok=true
# Check AZure settings
if  [ -z "$AZURE_LOCATION" ]; then echo AZURE_LOCATION must be set && varsok=false; fi
if  [ -z "$AZURE_PROJECT" ]; then echo AWSC_PROJECT must be set && varsok=false; fi
if  [ -z "$AZURE_AKS_NODES" ]; then echo AZURE_AKS_NODES must be set && varsok=false; fi

# Check Cloud One Container Security (aka Deep Security Smart Check) settings (for pre-runtime scanning)
if  [ -z "$DSSC_NAMESPACE" ]; then echo DSSC_NAMESPACE must be set && varsok=false; fi
if  [ -z "$DSSC_AC" ]; then echo DSSC_AC must be set && varsok=false; fi
if  [ -z "$DSSC_USERNAME" ]; then echo DSSC_USERNAME must be set && varsok=false; fi
if  [ -z "$DSSC_TEMPPW" ]; then echo DSSC_TEMPPW must be set && varsok=false; fi
if  [ -z "$DSSC_PASSWORD" ]; then echo DSSC_PASSWORD must be set && varsok=false; fi
if  [ -z "$DSSC_HOST" ]; then echo DSSC_HOST must be set && varsok=false; fi
if  [ -z "$DSSC_REGUSER" ]; then echo DSSC_REGUSER must be set && varsok=false; fi
if  [ -z "$DSSC_REGPASSWORD" ]; then echo DSSC_REGPASSWORD must be set && varsok=false; fi

if  [ -z "$APP_GIT_URL1" ]; then echo APP_GIT_URL1 must be set && varsok=false; fi
if  [ -z "$APP_GIT_URL2" ]; then echo APP_GIT_URL2 must be set && varsok=false; fi
if  [ -z "$APP_GIT_URL3" ]; then echo APP_GIT_URL3 must be set && varsok=false; fi

#check Application Security settings (for runtime protection)
if  [ -z "$TREND_AP_KEY" ]; then echo TREND_AP_KEY must be set && varsok=false; fi
if  [ -z "$TREND_AP_SECRET" ]; then echo TREND_AP_SECRET must be set && varsok=false; fi

if  [ "$varsok" = false ]; then xxxexit ; fi
printf '%s\n' "OK"

printf '%s\n' "--------------------------"
printf '%s\n' "Setting up Project ${AZURE_PROJECT} "
printf '%s\n' "--------------------------"

#env | grep -i AZURE_
# configure AZ cli
###OLD###printf '%s\n' "Configuring AZ CLI"
###OLD###cat <<EOF>~/.aws/credentials
###OLD###[default]
###OLD###aws_access_key_id=$AWS_ACCESS_KEY_ID
###OLD###aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
###OLD###region=$AZURE_LOCATION
###OLD###output=json
###OLD###EOF
###OLD###rolefound="false"
###OLD###AWS_ROLES=(`aws iam list-roles | jq -r '.Roles[].RoleName ' | grep ${AWS_PROJECT} `)
###OLD###for i in "${!AWS_ROLES[@]}"; do
###OLD###  if [[ "${AWS_ROLES[$i]}" = "${AWS_PROJECT}EksClusterCodeBuildKubectlRole" ]]; then
###OLD###     printf "%s\n" "Reusing existing EksClusterCodeBuildKubectlRole: ${AWS_ROLES[$i]} "
###OLD###     rolefound="true"
###OLD###  fi
###OLD###done
###OLD###if [[ "${rolefound}" = "false" ]]; then
###OLD###  printf "%s\n" "Creating Role ${AWS_PROJECT}EksClusterCodeBuildKubectlRole"
###OLD###  export ACCOUNT_ID=`aws sts get-caller-identity | jq -r '.Account'`
###OLD###  TRUST="{ \"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Principal\": { \"AWS\": \"arn:aws:iam::${ACCOUNT_ID}:root\" }, \"Action\": \"sts:AssumeRole\" } ] }"
###OLD###  #TRUST="{ \"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Resource\": { \"AWS\": \"arn:aws:iam::${ACCOUNT_ID}:role/*\" }, \"Action\": \"sts:AssumeRole\" } ] }"
###OLD###  echo '{ "Version": "2012-10-17", "Statement": [ { "Effect": "Allow", "Action": "eks:Describe*", "Resource": "*" } ] }' > /tmp/iam-role-policy
###OLD###  aws iam create-role --role-name ${AWS_PROJECT}EksClusterCodeBuildKubectlRole --assume-role-policy-document "$TRUST" --output text --query 'Role.Arn'
###OLD###  aws iam put-role-policy --role-name ${AWS_PROJECT}EksClusterCodeBuildKubectlRole --policy-name eks-describe --policy-document file:///tmp/iam-role-policy
###OLD###fi

# Create Resource Group:
# -----------------------

#AKS Resource Group
printf '%s\n' "Azure Resource Group "
export AZURE_GROUP=( `az group list -o json| jq -r  ".[]|select(.name|test(\"${AZURE_PROJECT}\"))|.name"` )
#echo AZURE_GROUP= $AZURE_GROUP

if [[ "${AZURE_GROUP}" = "" ]]; then
  printf '%s\n' "Creating Resource Group: ${AZURE_PROJECT}"
  dummy=`az group create --name ${AZURE_PROJECT} --location ${AZURE_LOCATION}`
else
  printf "%s\n" "Reusing existing Resource Group ${AZURE_PROJECT}"
fi
export AZURE_GROUP=( `az group list -o json| jq -r  ".[]|select(.name|test(\"${AZURE_PROJECT}\"))|.name"` )

# install tools
. ./tools.sh

#create cluster
. ./aksCluster.sh

# deploy SmartCheck
. ./smartcheck.sh

#adding registries
. ./SmartcheckInternalRepo.sh
. ./smartcheckDemoRepo.sh
. ./add_C1CS.sh

# add the demo apps
. ./demoApps.sh

# setup azure CodePipeline
. ./pipelines.sh

. ./smartcheckAddACR.sh

###OLD####delete the cluster
###OLD###az group delete --name AZURE_PROJECT --yes --no-wait###OLD###

###OLD####get the name of the nodepool
###OLD###myNodePool=`az aks show --resource-group $AZURE_PROJECT --name $AZURE_PROJECT --query agentPoolProfiles | jq '.[].name'`###OLD###

###OLD####scale the nodepool
###OLD####!!! cannot scale to 0
###OLD###az aks scale --resource-group AZURE_PROJECT --name AZURE_PROJECT --node-count 0 --nodepool-name $myNodePool###OLD###

###OLD#### Delete the cluster
###OLD#### -------------------
###OLD###az group delete --name $AZURE_PROJECT --location $AZURE_REGION
