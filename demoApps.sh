dummytestreference
#!/bin/bash
printf '%s\n' "---------------------"
printf '%s\n' " Adding Demo-apps "
printf '%s\n' "---------------------"

#  az devops project create

# az repos create --name FabrikamApp
#  -> import from git
#      from: https://github.com/felipecosta09/TrendMicro-S2-AzureDevOps
#git push the 3 local projects

#Create an Azure Pipeline for a repository hosted in a Azure Repo in the same project
#az pipelines create --name 'ContosoBuild' --description 'Pipeline for contoso project'  --repository SampleRepoName --branch master --repository-type tfsgit

#Authenticate to your internal Azure GIT repository using your Personal Access Token
#echo $AZURE_DEVOPS_EXT_PAT | az devops login --organization $AZURE_ORGANIZATION_URL
#git -c http.extraHeader="Authorization: Basic ${AZURE_DEVOPS_EXT_PAT}" clone ${AZURE_GIT_REPO_URL1}

# Sourcing variables
##. ./cloudOneCredentials.txt
#checking required variables
varsok=true
if  [ -z "$AZURE_LOCATION" ]; then echo AZURE_LOCATION must be set && varsok=false; fi
if  [ -z "$AZURE_ORGANIZATION" ]; then echo AZURE_ORGANIZATION must be set && varsok=false; fi
if  [ -z "$AZURE_ORGANIZATION_URL" ]; then echo AZURE_ORGANIZATION_URL must be set && varsok=false; fi
if  [ -z "${APP_GIT_URL1}" ]; then echo APP_GIT_URL1 must be set && varsok=false; fi
if  [ -z "${APP_GIT_URL2}" ]; then echo APP_GIT_URL2 must be set && varsok=false; fi
if  [ -z "${APP_GIT_URL3}" ]; then echo APP_GIT_URL3 must be set && varsok=false; fi
if  [ "$varsok" = false ]; then exitdebug 1 ; fi


function setupApp {
  #$1=appname
  #$2=downloadURL for application on public git
  # AZ devops Project
  printf '%s\n' "Azure devops project ${1} "

  export AZURE_PROJECTS=( `az devops project list --organization $AZURE_ORGANIZATION_URL --output json| jq -r ".value[].name"`)
  if [[ "${AZURE_PROJECTS}" =~ "${1}" ]]; then
    printf '%s \n' "Reusing existing Azure Project ${1}"
  else
    printf '%s \n' "Creating Azure Project ${1}"
    DUMMY=`az devops project create --name ${1} --description 'By CloudOneOnAzure' --source-control git  --visibility private --org $AZURE_ORGANIZATION_URL `
    #--output none    
  fi
  export AZURE_PROJECT_ID1=( `az devops project list --organization $AZURE_ORGANIZATION_URL  --output json| jq -r ".value[]|select(.name|test(\"${1}\"))|.id"` )
  echo AZURE_PROJECT_ID1=$AZURE_PROJECT_ID1

  # Azure ACR
  printf '%s\n' "Azure ACR registry ${1} "
  export AZURE_ACR_REPO_ID=( `az acr list --resource-group $AZURE_PROJECT --output json| jq -r ".[]|select(.name|test(\"${1}\"))|.id"` )
  echo AZURE_ACR_REPO_ID= $AZURE_ACR_REPO_ID

  if [[ "${AZURE_ACR_REPO_ID}" = "" ]]; then
    printf '%s \n' "Creating ACR registry ${1}"
    DUMMY=`az acr create --resource-group $AZURE_PROJECT --name ${1} --sku Basic`
  else
    printf '%s \n' "Reusing existing ACR registry $AZURE_PROJECT"
  fi
  export AZURE_ACR_REPO_ID=( `az acr list --resource-group $AZURE_PROJECT --output json| jq -r ".[]|select(.name|test(\"${1}\"))|.id"` )
  echo AZURE_ACR_REPO_ID= $AZURE_ACR_REPO_ID

  export AZURE_ACR_LOGINSERVER=`az acr list --resource-group $AZURE_PROJECT --output json| jq -r ".[]|select(.name|test(\"${1}\"))|.loginServer"`




  #!/bin/bash

  # Modify for your environment.
  # ACR_NAME: The name of your Azure Container Registry
  # SERVICE_PRINCIPAL_NAME: Must be unique within your AD tenant
  export ACR_NAME=${1}
  SERVICE_PRINCIPAL_NAME=$AZURE_PROJECT
    #acr-service-principal
  echo SERVICE_PRINCIPAL_NAME= $SERVICE_PRINCIPAL_NAME
  # Obtain the full registry ID for subsequent command args
  export ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --resource-group $AZURE_PROJECT --query id --output tsv)
  echo ACR_REGISTRY_ID= $ACR_REGISTRY_ID

  # Create the service principal with rights scoped to the registry.
  # Default permissions are for docker pull access. Modify the '--role'
  # argument value as desired:
  # acrpull:     pull only
  # acrpush:     push and pull
  # owner:       push, pull, and assign roles



  echo Debug Getting adSpList
  export ADSPLIST=`az ad sp list --all | jq -r '.[]| select(.displayName| contains("${AZURE_PROJECT}"))|[.displayName,.appId]'`
  if [[ "${ADSPLIST}" = "" ]]; then
    echo Debug Getting Passwd
    export SP_PASSWD=$(az ad sp create-for-rbac --name http://$SERVICE_PRINCIPAL_NAME --scopes $ACR_REGISTRY_ID --role owner --query password --output tsv)
    echo SP_PASSWD=$SP_PASSWD
    echo Debug getting App_ID
    export SP_APP_ID=$(az ad sp show --id http://$SERVICE_PRINCIPAL_NAME --query appId --output tsv)
    echo SP_APP_ID=$SP_APP_ID
    # Output the service principal's credentials; use these in your services and
    # applications to authenticate to the container registry.
    echo "Service principal ID: $SP_APP_ID"   #05763d5a-77db-4af8-8f63-f1d5e4318f19
    echo "Service principal password: $SP_PASSWD"    #tKsc-RTbt34i2jaPR94g9X5pWtQChg~2IE
    #login to ACR
    #docker login c1appsecmoneyx.azurecr.io  -u $SP_APP_ID -p $SP_PASSWD
  fi


  # Internal Azure GIT repo
  export AZURE_GIT_REPOS=(`az repos list --project ${1} | jq -r '.[].name'`)
  export AZURE_GIT_IDS=(`az repos list --project ${1} | jq -r '.[].id'`)
  export AZURE_GIT_PROJECT_IDS=(`az repos list --project ${1} | jq -r '.[].project.id'`)
  echo AZURE_GIT_REPOS=$AZURE_GIT_REPOS

  #Dummy Repo
  #Azure does not allow you to delete the last repo, but we will want to delete the project repot to initialize it, so we will create a dummy repo to ensure that always one repo exists
  dummyrepofound="false"
  for i in "${!AZURE_GIT_REPOS[@]}"; do
    echo AZURE_GIT_REPOS[$i] = "${AZURE_GIT_REPOS[$i]}"
    if [[ "${AZURE_GIT_REPOS[$i]}"  =~ "dummyRepo"  ]]; then
      echo Existing DummyRepo found
      dummyrepofound="true"
    fi
  done
  if [[ "${dummyrepofound}"  == "false"  ]]; then
      echo Creating dummy repo
      dummy=`az repos create --name dummyRepo --project ${1}`
  fi

  echo '-------------------'
  az repos list --project ${1} --output json| jq -r
  echo '-------------------'
  for i in "${!AZURE_GIT_REPOS[@]}"; do
    ##if [[ "${AZURE_GIT_REPOS[$i]}"  =~ "${1}"  ]]; then
    if [[ "${AZURE_GIT_REPOS[$i]}"  =~ "${1}"  ]]; then
      echo i= $i
      echo AZURE_GIT_REPO = "${AZURE_GIT_REPOS[$i]}"
      echo AZURE_GIT_ID = "${AZURE_GIT_IDS[$i]}"
      echo AZURE_GIT_PROJECT_IDS = "${AZURE_GIT_PROJECT_IDS[$i]}"
      printf '%s \n' "Deleting old internal Azure GIT repository: ${1}"
      az repos delete --project ${AZURE_GIT_PROJECT_IDS[$i]} --id ${AZURE_GIT_IDS[$i]}  -y
    fi
  done
  echo '-------------------'
  az repos list --project ${1} --output json| jq -r
  echo '-------------------'

  printf '%s \n' "Creating internal Azure GIT repository ${1}"
  DUMMY=`az repos create --name ${1} --project ${1}`
  export AZURE_GIT_REPO_URL1=( `az repos list --project ${1} --output json| jq -r ".[]|select(.name|test(\"${1}\"))|.webUrl"` )
  echo AZURE_GIT_REPO_URL1=$AZURE_GIT_REPO_URL1



  RETURN_DIR=`pwd`
  mkdir -p  ../apps

  cd ../apps
  dirname=`echo $APP_GIT_URL1 | awk -F"/" '{print $NF}' | awk -F"." '{ print $1 }' `
  #echo $APP_GIT_URL1
  echo dirname= $dirname
  #clone for public git if not already done so
  if [ -d "${dirname}" ]; then
     printf '%s\n' "Directory ../apps/${dirname} already exists.  Not downloading app again from public GIT"
  else
     printf '%s\n' "Importing ${dirname} from public git"
     git clone $APP_GIT_URL1
     printf '%s\n' "Deleting ${dirname}/.git directory (.git from github)"
     rm -rf ${dirname}/.git
  fi


  cd $dirname
  # removing the link to github as this will be linked to the internal Azure GIT
  # # #if [ -d ".git" ]; then
    printf '%s\n'  ".git directory found, skipping git init"
  # # #else
    printf '%s\n'  "initializing git for internal Azure GIT"
    echo AZURE_DEVOPS_EXT_PAT=  $AZURE_DEVOPS_EXT_PAT
    AZURE_GIT_REPO_URL1_AUTH="https://${AZURE_ORGANIZATION}:${AZURE_DEVOPS_EXT_PAT}@dev.azure.com/${AZURE_ORGANIZATION}/${1}/_git/${1}"
    echo AZURE_GIT_REPO_URL1_AUTH = $AZURE_GIT_REPO_URL1_AUTH
    
    git init
    git config --global user.name ${1}
    git config --global user.email ${AZURE_PROJECT}@example.com
    git config --global push.default simple
    git remote remove origin
    git remote remove upstream
    git remote add origin ${AZURE_GIT_REPO_URL1_AUTH}
    git remote add upstream ${AZURE_GIT_REPO_URL1_AUTH}
    git remote add azure https://${AZURE_DEVOPS_EXT_PAT}@${AZURE_ORGANIZATION_URL//https:\/\//}/${APP1}/_git/${APP1}
    printf '%s\n'  "pushing a dummy change to trigger a pipeline"
    #mv azure-pipelines.yml azure-pipelines.`date +%s`
    #mv manifests manifests.`date +%s`
    echo " " >> README.MD
    git add .
    git commit -m "commit by \"add_demoApps\""
    git push ${AZURE_GIT_REPO_URL1_AUTH}

  #4. pipeline will pick it up, build an Image, send it to SmartCheck..
  cd $RETURN_DIR
}


printf '%s\n' "Deploying ${APP}1 (from ${APP_GIT_URL1})"
printf '%s\n' "---------------------------------------------"
setupApp ${APP1} ${APP_GIT_URL1}

####printf '%s\n' "Deploying ${APP}2 (from ${APP_GIT_URL2})"
####printf '%s\n' "---------------------------------------------"
####setupApp ${APP2} ${APP_GIT_URL2}
####printf '%s\n' "Deploying ${APP}3 (from ${APP_GIT_URL3})"
####printf '%s\n' "---------------------------------------------"
####setupApp ${APP3} ${APP_GIT_URL3}
####return #exit
#####optionally (if the app makes it through the scanning)
#####it takes a while for the apps to get processed through the pipeline
#####running the getUrl below will typically result in errors because the apps have not been deployed yet####

####getUrl ${APP1}
#####getUrl ${APP2}
#####getUrl ${APP3}
#####exit
