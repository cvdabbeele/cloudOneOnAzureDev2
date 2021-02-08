#!/bin/bash
printf '%s\n' "--------------------------"
printf '%s\n' "        Tools             "
printf '%s\n' "--------------------------"


if [[ "`az extension list | grep \"azure-devops\"`" = "" ]]; then
  printf '%s\n' "Adding Azure-devops extensions "
  az extension add --name azure-devops
elso
  echo nothing to do... tools are getting automaically installed when they are called the first time
fi


#Download and install kubectl, the Kubernetes command-line tool. Download and install kubelogin, a client-go credential (exec) plugin implementing azure authentication.
#You do not need to install the kubectl for AKS if you use the Azure Cloud Shell, that's a default tool installed in it. See all the default tools installed in Azure Cloud Shell.
#az aks install-cli --install-location ~/.azure-kubectl/kubectl.exe
  # Downloading client to "/home/chris/.azure-kubectl/kubectl.exe" from "https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl"
  #Please ensure that /home/chris/.azure-kubectl is in your search PATH, so the `kubectl.exe` command can be found.

#login to Azure devops
#printf '%s\n' "Logging in to AZ devops..."
echo $AZURE_DEVOPS_EXT_PAT | az devops login --organization $AZURE_ORGANIZATION_URL
# https://github.com/Azure/azure-devops-cli-extension/issues/486
# explicit loging not required and even throwing an error
# as long as $AZURE_DEVOPS_EXT_PAT is defined, login will be transparent