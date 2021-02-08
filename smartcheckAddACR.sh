#!/bin/bash
#printf "Checking required variables..."
printf '%s\n' "--------------------------------------------------------"
printf '%s\n' " Adding the ACR repository to Smart Check: "
printf '%s\n' "--------------------------------------------------------"
. ./cloudOneCredentials.txt
varsok=true
if  [ -z "${DSSC_USERNAME}" ]; then echo DSSC_USERNAME must be set && varsok=false; fi
if  [ -z "${DSSC_PASSWORD}" ]; then echo DSSC_PASSWORD must be set && varsok=false; fi
if  [ -z "${DSSC_HOST}" ]; then echo DSSC_HOST must be set && varsok=false; fi
if  [ "$varsok" = false ]; then exit 1 ; fi
#printf "Get a DSSC_BEARERTOKEN \n"
#-------------------------------
DSSC_BEARERTOKEN=$(curl -s -k -X POST https://${DSSC_HOST}/api/sessions -H "Content-Type: application/json"  -H "Api-Version: 2018-05-01" -H "cache-control: no-cache" -d "{\"user\":{\"userid\":\"${DSSC_USERNAME}\",\"password\":\"${DSSC_PASSWORD}\"}}" | jq '.token' | tr -d '"')


printf '%s \n' "    Adding ACR repository to Smart Check: "
export AZURE_ACR_LOGINSERVER=`az acr list --resource-group $AZURE_PROJECT --output json| jq -r ".[]|select(.name|test(\"${APP1}\"))|.loginServer"`


export DSSC_BEARERTOKEN=$(curl -s -k -X POST https://${DSSC_HOST}/api/sessions -H "Content-Type: application/json"  -H "Api-Version: 2018-05-01" -H "cache-control: no-cache" -d "{\"user\":{\"userid\":\"${DSSC_USERNAME}\",\"password\":\"${DSSC_PASSWORD}\"}}" | jq '.token' | tr -d '"')
#echo DSSC_BEARERTOKEN=$DSSC_BEARERTOKEN


export DSSC_REPOID=$(curl -s -k -X POST https://$DSSC_HOST/api/registries?scan=true -H "Content-Type: application/json" -H "Api-Version: 2018-05-01" -H "Authorization: Bearer $DSSC_BEARERTOKEN" -H 'cache-control: no-cache' -d "{\"name\":\"ACR  Registry__xxx\",\"description\":\"added by  ChrisV\n\",\"host\":\"${AZURE_ACR_LOGINSERVER}\",\"credentials\":{\"username\":\"${SP_APP_ID}\",\"password\":\"$SP_PASSWD\"},\"insecureSkipVerify\":"true"}" | jq '.id')
echo $DSSC_REPOID


#TODO: write a test to verify if the Repository was successfully added
