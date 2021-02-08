#!/bin/bash
printf '%s\n' "-------------------------------"
printf '%s\n' "Creating Azure pipelines "
printf '%s\n' "-------------------------------"




# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# TO DO 
# Make this pipeline work for ${APP1} ${APP2} and ${APP3}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# Sourcing variables
#. ./00_define_vars.sh
. ./cloudOneCredentials.txt

varsok=true
if  [ -z "${AZURE_LOCATION=}" ]; then echo AZURE_LOCATION= must be set && varsok=false; fi
if  [ -z "${AZURE_PROJECT}" ]; then echo AZURE_PROJECT must be set && varsok=false; fi
if  [ -z "${AZURE_ORGANIZATION}" ]; then echo AZURE_ORGANIZATION must be set  && varsok=false; fi
if  [ -z "${DSSC_USERNAME}" ]; then echo DSSC_USERNAME must be set  && varsok=false; fi
if  [ -z "${DSSC_PASSWORD}" ]; then echo DSSC_PASSWORD must be set && varsok=false; fi
if  [ -z "${DSSC_HOST}" ]; then echo DSSC_HOST must be set && varsok=false; fi
if  [ -z "${DSSC_REGUSER}" ]; then echo DSSC_REGUSER must be set && varsok=false; fi
if  [ -z "${DSSC_REGPASSWORD}" ]; then echo DSSC_REGPASSWORD must be set && varsok=false; fi
if  [ "$varsok" = false ]; then exitdebug 1 ; fi


RETURN_DIR=`pwd`
dirname=`echo $APP_GIT_URL1 | awk -F"/" '{print $NF}' | awk -F"." '{ print $1 }' `
echo dirname= $dirname
cd ../apps/${dirname}
mkdir -p work 

#see also: https://mohitgoyal.co/2019/07/16/working-with-azure-devops-pipelines-using-command-line/
AZURE_PIPELINE_IDS=(`az pipelines list  --project $APP1 | jq -r ".[]|select(.name|test(\"${APP1}\"))|.id"`)
echo AZURE_PIPELINE_IDS=${AZURE_PIPELINE_IDS}

for i in "${!AZURE_PIPELINE_IDS[@]}"; do
   echo "Delting pipeline with ID: ${AZURE_PIPELINE_IDS[$i]}"
   az pipelines delete --id ${AZURE_PIPELINE_IDS[$i]} --project $APP1 -y
done
#if  [ "${AZURE_PIPELINE_ID}" = "" ]
#then
#  printf '%s\n' "DEBUG No existing pipelines found "
#   else
#  printf '%s\n' "Deleting old Azure pipeline "
#  az pipelines delete --id ${AZURE_PIPELINE_ID} --project $APP1 -y
#fi
if [[ -f "azure-pipelines.yml" ]]; then
   printf '%s\n' "Deleting old local file azure-pipelines.yml for $APP1"
   #mv azure-pipelines.yml azure-pipelines.`date +%s`
   rm -rf azure-pipelines.yml
   printf '%s\n' "Pushing changes to ${APP1} registry"
   git add .
   git commit -m "commit by \"add_demoApps\""
   AZURE_GIT_REPO_URL1_AUTH="https://${AZURE_ORGANIZATION}:${AZURE_DEVOPS_EXT_PAT}@dev.azure.com/${AZURE_ORGANIZATION}/${APP1}/_git/${APP1}"
   git push ${AZURE_GIT_REPO_URL1_AUTH}
fi
if [ -d "manifests" ]; then
   printf '%s\n' "Deleting old local directory manifests for $APP1"
   #mv manifests manifests.`date +%s`
   rm -r manifests
   printf '%s\n' "Pushing changes to ${APP1} registry"
   git add .
   git commit -m "commit by \"add_demoApps\""
   AZURE_GIT_REPO_URL1_AUTH="https://${AZURE_ORGANIZATION}:${AZURE_DEVOPS_EXT_PAT}@dev.azure.com/${AZURE_ORGANIZATION}/${APP1}/_git/${APP1}"
   git push ${AZURE_GIT_REPO_URL1_AUTH}
fi



printf '%s\n' "Creating pipeline $APP1"
# cannot do the full automated version because I can't figure out (yet) how to get 
# the dockerRegistryServiceConnection: e.g. '38d9fcc9-8e09-4f1b-be98-38c42fcec0bb' 
#export AZURE_PIPELINE1_ID=`
#az pipelines create --name $APP1.test`date +%s` \
#  --description "Pipeline for $APP1" \
#  --project $APP1 \
#  --repository ${APP1} \
#  --branch master  \
#  --repository-type tfsgit \
#  --yml-path azure-pipelines.yml | jq -r '.definition.id'
#`

printf '%s\n' "You will be asked 9 questions to configure the Pipeline"
read  -n 1 -p "Press ENTER to start creating the pipeline -1" dummyinput
read  -n 1 -p "Press ENTER to start creating the pipeline -2" dummyinput
read  -n 1 -p "Press ENTER to start creating the pipeline -3" dummyinput
read  -n 1 -p "Press ENTER to start creating the pipeline -4" dummyinput
read  -n 1 -p "Press ENTER to start creating the pipeline -5" dummyinput

#the following command will invoke 9 questions 
printf '%s\n' "      Which template do you want to use for this pipeline?  "
printf '%s\n' "          Choose Deploy to Azure Kubernetes Service"
printf '%s\n' "          Choose Deploy to Azure Kubernetes Service"
printf '%s\n' "      The template requires a few inputs. We will help you fill them out"
printf '%s\n' "      Using your default Azure subscription Pay-As-You-Go for fetching AKS clusters."
printf '%s\n' "          WAIT"
# Which kubernetes cluster do you want to target for this pipeline?
#  [1] cloudone14
# printf '%s\n' "          ENTER"
# Which kubernetes namespace do you want to target?
#  [1] Create new
#  [2] c1appsecmoneyx
#  [3] default
# Which Azure Container Registry do you want to use for this pipeline?
#  [1] c1appsecuploaderregistrybbbe006b
#  [2] c1appsecmoneyx
# Please enter a choice [Default choice(1)]: 
# Enter a value for Image Name [Press Enter for default: cappsecmoneyxgit]:
# Enter a value for Service Port [Press Enter for default: 8080]:
# Please enter a value for Enable Review App flow for Pull Requests: 
# Do you want to view/edit the template yaml before proceeding?
#  [1] Continue with generated yaml
#  [2] View or edit the yaml
# Please enter a choice [Default choice(1)]: 
# 
# Files to be added to your repository (3)
# 1) manifests/deployment.yml
# 2) manifests/service.yml
# 3) azure-pipelines.yml
# 
# How do you want to commit the files to the repository?
#  [1] Commit directly to the master branch.
#  [2] Create a new branch for this commit and start a pull request.
# Please enter a choice [Default choice(1)]: 



# az pipelines create --name ${APP1}man --branch master --org $AZURE_ORGANIZATION_URL --project $APP1 --repository-type tfsgit --repository ${AZURE_ORGANIZATION_URL}/${APP1}/_git/${APP1}



# TO DO  Put the below in a loop until the user is OK with the answers
az pipelines create \
  --name ${APP1} \
  --branch master  \
  --description "Pipeline for ${APP1}" \
  --org ${AZURE_ORGANIZATION_URL} \
  --project $APP1 \
  --repository-type tfsgit \
  --repository ${AZURE_ORGANIZATION_URL}/${APP1}/_git/${APP1}
  # AZURE_GIT_REPO_URL1_AUTH="https://${AZURE_ORGANIZATION}:${AZURE_DEVOPS_EXT_PAT}@dev.azure.com/${AZURE_ORGANIZATION}/${APP1}/_git/${APP1}"
  #https://chrisvandenabbeele@dev.azure.com/chrisvandenabbeele/c1appsecmoneyx/_git/c1appsecmoneyx

# END  TO DO  Put the below in a loop until the user is OK with the answers


#printf '%s\n' "Saving existing pipeline variables to AZ_PIPELINE_VARS.tmp"
#az pipelines variable list  --pipeline-name $APP1 --project $APP1 >  AZ_PIPELINE_VARS.tmp
printf '%s\n' "Exporting variables for Azure pipelines (if not already existing)"
export TAG="dummyTag"
export myvar="dummyMyVarFromScript"
export PIPELINE_VARS=(SP_APP_ID SP_PASSWD DSSC_HOST DSSC_USERNAME DSSC_TEMPPW DSSC_PASSWORD DSSC_REGUSER DSSC_REGPASSWORD TREND_AP_KEY TREND_AP_SECRET APP1 SP_APP_ID SP_PASSWD AZURE_ACR_LOGINSERVER  AZURE_PROJECT TAG myvar)
for pipelineVar in ${PIPELINE_VARS[@]}; do
  echo Checking pipelineVar=${pipelineVar}
  if  [ "` grep \"${pipelineVar}\" AZ_PIPELINE_VARS.tmp `" = "" ]
  then
    echo Exporting ${pipelineVar} to pipeline
    #echo '${pipelineVar} ='  ${pipelineVar}
    #echo '${!pipelineVar} =' ${!pipelineVar}
    dummy=`az pipelines variable create --pipeline-name $APP1 --project $APP1 --name ${pipelineVar} --value ${!pipelineVar}`
  fi
done



AZURE_GIT_REPO_URL1_AUTH="https://${AZURE_ORGANIZATION}:${AZURE_DEVOPS_EXT_PAT}@dev.azure.com/${AZURE_ORGANIZATION}/${APP1}/_git/${APP1}"
git pull ${AZURE_GIT_REPO_URL1_AUTH}
ls -latr


printf '%s\n' "" >> manifests/deployment.yml
echo "          env: "                     >> manifests/deployment.yml
echo "          - name: TREND_AP_KEY"      >> manifests/deployment.yml
echo "            value: _TREND_AP_KEY"    >> manifests/deployment.yml
echo "          - name: TREND_AP_SECRET"   >> manifests/deployment.yml
echo "            value: _TREND_AP_SECRET" >> manifests/deployment.yml


cat azure-pipelines.yml 
#cp azure-pipelines.yml azure-pipelines.orig.yml 
echo Inserting the SmartCheck scan part in the pipeline
grep "    - upload: manifests"  azure-pipelines.yml -B999 >work/azure-pipelines.part1.yml 
#cat work/azure-pipelines.part1.yml
echo 'removing "    - upload: manifests" from work/pipeline.part1; it is in part2 as well'
sed -i 's/    - upload: manifests//g' work/azure-pipelines.part1.yml
echo 'changing the buildAndPush command to build; the push part will be imported with the azure-pipelines-smartcheck-insert'
sed -i 's/command: buildAndPush/command: build/g' work/azure-pipelines.part1.yml
sed -i 's/Build and push an image to container registry/Build/g' work/azure-pipelines.part1.yml
#cat work/azure-pipelines.part1.yml
grep "    - upload: manifests"  azure-pipelines.yml -A999 >work/azure-pipelines.part2.yml 
#cat work/azure-pipelines.part2.yml 
#echo Inserting Smartcheck scanning into azure-pipeline.yml file

cat ${RETURN_DIR}/azure-pipelines-smartcheck-insert.yml >> work/azure-pipelines.part1.yml

cat work/azure-pipelines.part2.yml >> work/azure-pipelines.part1.yml  
echo step10
echo "take section up to               dockerRegistryEndpoint: $(dockerRegistryServiceConnection)"
grep '              dockerRegistryEndpoint: $(dockerRegistryServiceConnection)'  work/azure-pipelines.part1.yml -B999 >work/azure-pipelines2.yml 

cat work/azure-pipelines2.yml



echo "adding Set Environment Variables for Cloud One Application Security"
printf '%s\n' " " >>  work/azure-pipelines2.yml
cat ${RETURN_DIR}/azure-pipelines-C1AS.yml >>  work/azure-pipelines2.yml
echo step 11
cat work/azure-pipelines2.yml

echo "re-add the part from \"task: KubernetesManifest@0\" and onwards"
echo '          - task: KubernetesManifest@0' >> work/azure-pipelines2.yml
grep 'displayName: Deploy to Kubernetes cluster'  work/azure-pipelines.yml -A999 >>work/azure-pipelines2.yml
echo step 12
cat work/azure-pipelines2.yml

###echo step13 
###echo "          - task: KubernetesManifest@0" >> work/azure-pipelineslastpart.yml
###cat work/azure-pipelineslastparttemp.yml >> work/azure-pipelineslastpart.yml
###cat work/azure-pipelineslastpart.yml
##cat  work/azure-pipelineslastpart.yml >> work/azure-pipelines2.yml 

cp work/azure-pipelines2.yml azure-pipelines.yml

echo Make the pipeline trigger in "master" iso on "main"
sed -i 's/main/master/g' azure-pipelines.yml

ls -latr
cat azure-pipelines.yml 
printf '%s\n' "Pushing changes to ${APP1} registry"
git add .
git commit -m "commit by \"add_demoApps\""
AZURE_GIT_REPO_URL1_AUTH="https://${AZURE_ORGANIZATION}:${AZURE_DEVOPS_EXT_PAT}@dev.azure.com/${AZURE_ORGANIZATION}/${APP1}/_git/${APP1}"
git push ${AZURE_GIT_REPO_URL1_AUTH}
read  -n 1 -p "Press ENTER to continue" dummyinput


#echo AZURE_PIPELINE1_ID = $AZURE_PIPELINE1_ID
#az pipelines create --name $APP1.test`date +%s` \
#  --description "Pipeline for $APP1" \
#  --project $APP1 \
#  --repository ${APP1}\
#  --branch master  \
#  --repository-type tfsgit \
#  --yml-path azure-pipelines.yml

##   AZURE_PIPELINE_ID=`az pipelines list  --project $APP1 | jq -r ".[]|select(.name|test(\"${APP1}\"))|.id"`  && az pipelines delete --id ${AZURE_PIPELINE_ID} --project $APP1 -y

#az pipelines variable list --pipeline-name $APP1 --project $APP1
cd ${RETURN_DIR}