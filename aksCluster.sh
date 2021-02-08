
#!/bin/bash
printf '%s \n'  "-----------------------"
printf '%s \n'  "    AKS cluster"
printf '%s \n'  "-----------------------"

# Check required variables
varsok=true


if  [ -z "$AZURE_LOCATION" ]; then echo AZURE_LOCATION must be set && varsok=false; fi
if  [ -z "$AZURE_PROJECT" ]; then echo AZURE_PROJECT must be set && varsok=false; fi
#if  [ -z "$AWS_CODECOMMIT_REPO" ]; then echo AWS_CODECOMMIT_REPO must be set && varsok=false; fi
if  [ -z "$AZURE_AKS_NODES" ]; then echo AZURE_AKS_NODES must be set && varsok=false; fi
#if  [ -z "$AWS_EKS_CLUSTERNAME" ]; then echo AWS_EKS_CLUSTERNAME must be set && varsok=false; fi

if  [ "$varsok" = false ]; then printf '%s\n' "Missing variables" && xxxexit ; fi

#Resource Group

###az group list | jq -r '.[].name'






#AKS cluster
AZURE_CLUSTER_exists="false"
export AZURE_CLUSTERS=( `az aks list -o json| jq -r '.[].name'` )
for i in "${!AZURE_CLUSTERS[@]}"; do
  #printf "%s" "cluster $i =  ${AZURE_CLUSTERS[$i]}.........."
  if [[ "${AZURE_CLUSTERS[$i]}" =~ "${AZURE_PROJECT}" ]]; then
      printf "%s\n" "Reusing existing AKS cluster ${AZURE_PROJECT}"
      AZURE_CLUSTER_exists="true"
      break
  fi
done

if [[ "${AZURE_CLUSTER_exists}" = "true" ]]; then
    printf "%s\n" "Reusing existing cluster ${AZURE_PROJECT}"
else
    printf '%s\n' "Creating AKS cluster: ${AZURE_PROJECT}"
    starttime=`date +%s`
    printf '%s\n' "Creating a ${AZURE_AKS_NODES}-node AKS cluster named: ${AZURE_PROJECT} in location ${AZURE_LOCATION}"

    printf '%s\n' "This may take up to 10 minutes (started at: `date`)"
    # https://docs.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest#az-aks-create
    DUMMY=`az aks create --resource-group $AZURE_PROJECT --name $AZURE_PROJECT --node-count $AZURE_NROFNODES --enable-addons monitoring  --load-balancer-managed-outbound-ip-count 1 --generate-ssh-keys`
    endtime="$(date +%s)"
    printf '%s\n' "Cloudformation Stacks deployed.  Elapsed time: $((($endtime-$starttime)/60)) minutes"

    #printf '%s\n' "Waiting for Cloudformation stack \"managed-smartcheck-cluster\" to be created."
    #aws cloudformation wait stack-create-complete --stack-name eksctl-managed-smartcheck-cluster  --region $AZURE_LOCATION
    #printf '%s\n' "Waiting for Cloudformation stack \"managed-smartcheck-nodegroup-nodegroup\" to be created.  This may take a while"
    #aws cloudformation wait stack-create-complete --stack-name eksctl-eksctl-managed-smartcheck-nodegroup-nodegroup	 --region $AZURE_LOCATION
    endtime=`date +%s`
    printf '%s\n' "AKS cluster created.  Elapsed time: $((($endtime-$starttime)/60)) minutes"
    printf '%s\n' "Checking AKS cluster.  You should see your AKS cluster in the list below "
    az aks list  -o json | jq -r ' ( .[] | "Found cluster" + .name + " in location  " + .location)'
fi







#Connect to the Cluster:
#-----------------------
#if not on Azure Cloud Shell then install kubectl locally with the following command
#az aks install-cli

#Configure kubectl:
printf '%s \n'  "Configuring credentials for kubectl"
az aks get-credentials --resource-group $AZURE_PROJECT --name $AZURE_PROJECT
###kubectl get nodes

printf '%s \n'  "Deploying the Azure-vote test application.. just for testing... should be deleted "
#Deploy a test application (azure-vote)
#---------------------------------------
cat <<EOF >./azure-vote.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: azure-vote-back
spec:
  replicas: 1
  selector:
    matchLabels:
      app: azure-vote-back
  template:
    metadata:
      labels:
        app: azure-vote-back
    spec:
      nodeSelector:
        "beta.kubernetes.io/os": linux
      containers:
      - name: azure-vote-back
        image: redis
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 250m
            memory: 256Mi
        ports:
        - containerPort: 6379
          name: redis
---
apiVersion: v1
kind: Service
metadata:
  name: azure-vote-back
spec:
  ports:
  - port: 6379
  selector:
    app: azure-vote-back
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: azure-vote-front
spec:
  replicas: 1
  selector:
    matchLabels:
      app: azure-vote-front
  template:
    metadata:
      labels:
        app: azure-vote-front
    spec:
      nodeSelector:
        "beta.kubernetes.io/os": linux
      containers:
      - name: azure-vote-front
        image: microsoft/azure-vote-front:v1
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 250m
            memory: 256Mi
        ports:
        - containerPort: 80
        env:
        - name: REDIS
          value: "azure-vote-back"
---
apiVersion: v1
kind: Service
metadata:
  name: azure-vote-front
  annotations:
    service.beta.kubernetes.io/azure-dns-label-name: ${AZURE_PROJECT}
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: azure-vote-front
EOF

#deploy a test app
kubectl apply -f azure-vote.yaml

#monitor progress
kubectl get service azure-vote-front ##--watch


#test the app, browse to
  # http://<PUBLIC_IP>
  # http://${AZURE_PROJECT}.${AZURE_LOCATION}.cloudapp.azure.com
  # http://cloudone01.westeurope.cloudapp.azure.com/
