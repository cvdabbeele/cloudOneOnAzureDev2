#! /bin/bash

#still WIP state... needs work
printf '%s\n' "----------------------"
printf '%s\n' "Terminating environment"
printf '%s\n' "----------------------"
# check for variabels
#-----------------------
. 00_define_vars.sh

varsok=true
if  [ -z "${AZURE_LOCATION}" ]; then echo AZURE_LOCATION must be set && varsok=false; fi
if  [ -z "${AZURE_PROJECT}" ]; then echo AZURE_PROJECT must be set && varsok=false; fi
####if  [ "$varsok" = false ]; then exit ; fi

#delete deployed apps
printf "%s\n" "Removing deployments on AKS cluster"
kubectl delete deployment $APP1
kubectl delete deployment $APP2
kubectl delete deployment $APP3

# deleting AKS cluster
printf "%s\n" "Checking AKS clusters"
AZURE_CLUSTERS=( `az aks list -o json| jq -r '.[].name'` )
if [[ "${AZURE_CLUSTERS[$i]}" =~ "${AZURE_PROJECT}" ]]; then
   printf "%s\n" "Deleting AKS cluster ${AZURE_PROJECT}.   Please be patient, this can take a few minutes... (started at:`date`)"
   starttime="$(date +%s)"
   az aks delete --name ${AZURE_PROJECT} --resource-group ${AZURE_PROJECT} --yes
   endtime="$(date +%s)"
   printf '%s\n' "Cloudformation Stacks deployed.  Elapsed time: $((($endtime-$starttime)/60)) minutes"
fi

# deleting Resource Group
printf "%s\n" "Checking Resource Groups"
AZURE_GROUPS=(`az group list -o json| jq -r '.[].name'` )
for i in "${!AZURE_GROUPS[@]}"; do
  if [[ "${AZURE_GROUPS[$i]}" =~ "${AZURE_PROJECT}" ]]; then
    printf '%s\n' "Deleting Resource Group: ${AZURE_PROJECT}  Please be patient, this can take up to 15 minutes... (started at:`date`)"
    starttime="$(date +%s)"
    az group delete --name ${AZURE_PROJECT} --yes
    endtime="$(date +%s)"
    printf '%s\n' "Elapsed time: $((($endtime-$starttime)/60)) minutes"
  fi
done

#delete Project
printf "%s\n" "Checking Azure Projects"
AZURE_PROJECT_ID=( `az devops project list --organization $AZURE_ORGANIZATION_URL  --output json| jq -r ".value[]|select(.name|test(\"${APP1}\"))|.id"` )
echo $AZURE_PROJECT_ID
if [[ "${AZURE_PROJECT_ID}" = "" ]]; then
  printf '%s \n' "Azure Project $AZURE_PROJECT_ID not found"
else
    printf '%s \n' "Deleting Azure Project $AZURE_PROJECT_ID"
    az devops project delete --id $AZURE_PROJECT_ID --organization $AZURE_ORGANIZATION_URL  --output none --yes
fi
printf '%s \n' "~/.kube/config and ~/apps"
rm -rf ~/.kube/config
rm -rf ~/apps

#delete service principal (should be deleted with the project)
#printf "%s\n" "Deleting Service Principal for project ${AZURE_PROJECT_ID}"
#az ad sp delete --id `az ad sp list --display-name "${AZURE_PROJECT_ID}" | jq -r '.[].appId'`

#exit
###OLD###

###OLD#### Delete ECR repos
###OLD###printf "%s\n" "Deleting ECR Repositories"
###OLD###aws_ecr_repos=(`aws ecr describe-repositories --region ${AWS_REGION} | jq -r '.repositories[].repositoryName'`)
###OLD###aws_ecr_repo=''
###OLD###for i in "${!aws_ecr_repos[@]}"; do
###OLD###  #printf "%s" "Repo $i =  ${aws_ecr_repos[$i]}"
###OLD###  aws_ecr_repo=`echo ${1} | awk '{ print tolower($0) }'`
###OLD###  if [[ "${aws_ecr_repos[$i]}" =~ "${AWS_PROJECT}" ]]; then
###OLD###      printf "%s\n" "Deleting ECR repository: ${aws_ecr_repos[$i]}"
###OLD###      aws_ecr_repo_exists="true"
###OLD###      DUMMY=`aws ecr delete-repository --repository-name ${aws_ecr_repos[$i]} --region ${AWS_REGION} --force`
###OLD###  fi
###OLD###done###OLD###

###OLD#### Delete CodeCommit repos
###OLD###printf "%s\n" "Deleting CodeCommit Repositories"
###OLD###aws_cc_repos=(`aws codecommit list-repositories --region $AWS_REGION | jq -r '.repositories[].repositoryName'`)
###OLD###aws_cc_repo=''
###OLD###for i in "${!aws_cc_repos[@]}"; do
###OLD###  #printf '%s\n' "Checking CC Repo $i =  ${aws_cc_repos[$i]} ..........Comparing with ${1}"
###OLD###  if [[ "${aws_cc_repos[$i]}" =~ "${AWS_PROJECT}" ]]; then
###OLD###      printf "%s\n" "Deleting CodeCommit Repo "${aws_cc_repos[$i]}
###OLD###      DUMMY=`aws codecommit delete-repository --repository-name ${aws_cc_repos[$i]} --region ${AWS_REGION}`
###OLD###    fi
###OLD###done###OLD###

###OLD#### Delete Cloudformation Stacks
###OLD###printf "%s" "Deleting CloudFormation Pipeline Stacks..."
###OLD###aws_stack=""
###OLD###aws_stacks=(`aws cloudformation describe-stacks --output json --region $AWS_REGION| jq -r '.Stacks[].StackName'` )
###OLD###for i in "${!aws_stacks[@]}"; do
###OLD###  #printf "%s\n" "stack $i =  ${aws_stacks[$i]}"
###OLD###  if [[ "${aws_stacks[$i]}" =~ "${AWS_PROJECT}"  && "${aws_stacks[$i]}" =~ "Pipeline" ]]; then
###OLD###    printf "%s" "  ${aws_stacks[$i]}"
###OLD###    aws cloudformation delete-stack --stack-name ${aws_stacks[$i]} --region ${AWS_REGION}
###OLD###    aws cloudformation wait stack-delete-complete --stack-name ${aws_stacks[$i]}  --region ${AWS_REGION}
###OLD###  fi
###OLD###done
###OLD###printf "\n"###OLD###
###OLD###

###OLD####TBD: delete log groups###OLD###

###OLD#### delete cluster
###OLD###aws_eks_clusters=(`eksctl get clusters -o json | jq -r '.[].name'`)
###OLD###for i in "${!aws_eks_clusters[@]}"; do
###OLD###  #printf "%s" "cluster $i =  ${aws_eks_clusters[$i]}.........."
###OLD###  if [[ "${aws_eks_clusters[$i]}" =~ "${AWS_PROJECT}" ]]; then
###OLD###       printf "%s\n" "Deleting EKS cluster: ${AWS_PROJECT}"
###OLD###       printf "%s\n" "Please be patient, this can take up to 30 minutes... (started at:`date`)"
###OLD###      if [ -s  "${AWS_PROJECT}EksCluster.yml" ]; then
###OLD###        #eksctl delete cluster -f ${AWS_PROJECT}EksCluster.yml
###OLD###        starttime="$(date +%s)"
###OLD###        eksctl delete cluster ${AWS_PROJECT} --wait
###OLD###        sleep 30  #giving the delete cluster process a bit more time
###OLD###        endtime="$(date +%s)"
###OLD###        printf '%s\n' "Elapsed time: $((($endtime-$starttime)/60)) minutes"###OLD###

###OLD###      else
###OLD###        printf '%s \n' "PANIC: eks cluster with name ${AWS_PROJECT} exists, but file \"${AWS_PROJECT}EksCluster.yml\" does not"
###OLD###        printf '%s \n' "This situation should not exist.  Manual cleanup is required"
###OLD###      fi
###OLD###  fi
###OLD###done###OLD###
###OLD###

###OLD#### Cleaning up project VPC, starting with its dependencies
###OLD###aws_vpc_ids=(`aws ec2 describe-vpcs | jq -r ".Vpcs[].VpcId"`)
###OLD####find Project VPCs
###OLD###for i in "${!aws_vpc_ids[@]}"; do
###OLD###  #printf "%s\n" "vpc $i = ${aws_vpc_ids[$i]}.........."
###OLD###  aws_vpc_tags=`aws ec2 describe-vpcs --vpc-ids ${aws_vpc_ids[$i]} | jq -r '.Vpcs[].Tags'`  #no array needed here; just get thm all in one string
###OLD###  #printf "%s\n" "${aws_vpc_tags}"
###OLD###  if [[ ${aws_vpc_tags} =~ ${AWS_PROJECT} ]];then
###OLD###    printf "%s\n" "Found VPC belonging to project: ${aws_vpc_ids[$i]}"
###OLD###    aws_attachment_ids=(`aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=${aws_vpc_ids[$i]} | jq -r '.NetworkInterfaces[].Attachment.AttachmentId'`)
###OLD###      printf "%s\n" "Found aws_attachment_ids: ${aws_attachment_ids[@]}"
###OLD###    for j in "${!aws_attachment_ids[@]}"; do
###OLD###        printf "%s\n" "Found attachment ID ${aws_attachment_ids[$j]}"
###OLD###      if [[ "${aws_attachment_ids[$j]}" != "null" &&  "${aws_attachment_ids[$j]}" != "" ]];then
###OLD###        printf "%s\n" "Detaching ENI with attachment_id ${aws_attachment_ids[$j]}"
###OLD###        aws ec2 detach-network-interface --attachment-id  ${aws_attachment_ids[$j]}
###OLD###        #get ENI ID
###OLD###      else
###OLD###        printf "%s\n" "No Elastic Network Interface attached"
###OLD###      fi
###OLD###    done
###OLD###    aws_ENI_ids=(`aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=${aws_vpc_ids[$i]} | jq -r '.NetworkInterfaces[].NetworkInterfaceId'`)
###OLD###    for j in "${!aws_ENI_ids[@]}"; do
###OLD###        printf "%s\n" "Deleting ENI: ${aws_ENI_ids[$j]}"
###OLD###        aws ec2 delete-network-interface --network-interface-id ${aws_ENI_ids[$j]}
###OLD###    done
###OLD###    #delete Load Balancer
###OLD###    aws_lb=(`aws elb describe-load-balancers | jq -r ".LoadBalancerDescriptions[]|select(.VPCId|test(\"${aws_vpc_ids[$i]}\"))|.LoadBalancerName"`)###OLD###

###OLD###    for j in "${!aws_lb[@]}"; do
###OLD###      if [[ "${aws_lb[$j]}" != "null" &&  "${aws_lb[$j]}" != "" ]];then
###OLD###        printf "%s\n" "Deleting Load Balancer: xxxxx${aws_lb[$j]}xxxxxxxxx"
###OLD###        aws elb delete-load-balancer --load-balancer-name ${aws_lb[$j]}
###OLD###      else
###OLD###        printf "%s\n" "No Load Balancer attached"
###OLD###      fi
###OLD###    done###OLD###

###OLD###    #delete nat gateway
###OLD###    natgw_id=`aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=${aws_vpc_ids[$i]}"  | jq -r ".NatGateways[].NatGatewayId"`
###OLD###    if [[ "${natgw_id}" != "null" &&  "${natgw_id}" != "" ]];then
###OLD###      printf "%s\n" "Deleting NAT Gateway: ${natgw_id}"
###OLD###      aws ec2 delete-nat-gateway --nat-gateway-id ${natgw_id}
###OLD###    else
###OLD###      printf "%s\n" "No NAT Gateway attached"
###OLD###    fi###OLD###

###OLD###    #delete internet gateway
###OLD###    igw_id=`aws ec2 describe-internet-gateways | jq -r ".InternetGateways[]|
###OLD###    select(.Attachments[].VpcId|test(\"${aws_vpc_ids[$i]}\"))|.InternetGatewayId"`
###OLD###    if [[ "${igw_id}" != "null" &&  "${igw_id}" != "" ]];then
###OLD###      printf "%s\n" "Detaching Internet Gateway: ${igw_id}"
###OLD###      aws ec2 detach-internet-gateway --internet-gateway-id ${igw_id}  --vpc-id=${aws_vpc_ids[$i]}
###OLD###      printf "%s\n" "Deleting Internet Gateway: ${igw_id}"
###OLD###      aws ec2 delete-internet-gateway --internet-gateway-id ${igw_id}
###OLD###    else
###OLD###      printf "%s\n" "No Internet Gateway attached"
###OLD###    fi###OLD###

###OLD###    #delete security groups
###OLD###    printf "%s\n" "Checking Security Groups"
###OLD###    aws_sg_ids=(`aws ec2 describe-security-groups --filters Name=vpc-id,Values=${aws_vpc_ids[$i]} | jq -r '.SecurityGroups[].GroupId'`)
###OLD###    for j in "${!aws_sg_ids[@]}"; do
###OLD###        if [[ "`aws ec2 describe-security-groups --filters Name=group-id,Values=${aws_sg_ids[$j]} | jq -r '.SecurityGroups[].GroupName'`" != "default" ]];then
###OLD###          printf "%s\n" "Deleting Security Group: ${aws_sg_ids[$j]}"
###OLD###          aws ec2 delete-security-group --group-id ${aws_sg_ids[$j]}
###OLD###        fi
###OLD###    done###OLD###
###OLD###

###OLD###    #delete Subnets
###OLD###    printf "%s\n" "Checking Subnets"
###OLD###    aws_sn_ids=(`aws ec2 describe-subnets --filters Name=vpc-id,Values=${aws_vpc_ids[$i]} | jq -r '.Subnets[].SubnetId'`)
###OLD###    for j in "${!aws_sn_ids[@]}"; do
###OLD###        if [[ "`aws ec2 describe-subnets --filters Name=subnet-id,Values=${aws_sn_ids[j]} | jq -r '.Subnets[].DefaultForAz'`" != "true" ]];then
###OLD###          printf "%s\n" "Deleting Subnet: ${aws_sn_ids[$j]}"
###OLD###          aws ec2 delete-subnet --subnet-id ${aws_sn_ids[$j]}
###OLD###        fi
###OLD###    done###OLD###

###OLD###    printf "%s\n" "Checking dependencies of VPC: ${aws_vpc_ids[$i]}"
###OLD###    vpc=${aws_vpc_ids[$i]}
###OLD###    printf "%s\n" "Checking dependencies of VPC: $vpc"
###OLD###    aws ec2 describe-internet-gateways --filters 'Name=attachment.vpc-id,Values='$vpc | grep InternetGatewayId
###OLD###    aws ec2 describe-subnets --filters 'Name=vpc-id,Values='$vpc | grep SubnetId
###OLD###    aws ec2 describe-route-tables --filters 'Name=vpc-id,Values='$vpc | grep RouteTableId
###OLD###    aws ec2 describe-network-acls --filters 'Name=vpc-id,Values='$vpc | grep NetworkAclId
###OLD###    aws ec2 describe-vpc-peering-connections --filters 'Name=requester-vpc-info.vpc-id,Values='$vpc | grep VpcPeeringConnectionId
###OLD###    aws ec2 describe-vpc-endpoints --filters 'Name=vpc-id,Values='$vpc | grep VpcEndpointId
###OLD###    aws ec2 describe-nat-gateways --filter 'Name=vpc-id,Values='$vpc | grep NatGatewayId
###OLD###    aws ec2 describe-security-groups --filters 'Name=vpc-id,Values='$vpc | grep GroupId
###OLD###    aws ec2 describe-instances --filters 'Name=vpc-id,Values='$vpc | grep InstanceId
###OLD###    aws ec2 describe-vpn-connections --filters 'Name=vpc-id,Values='$vpc | grep VpnConnectionId
###OLD###    aws ec2 describe-vpn-gateways --filters 'Name=attachment.vpc-id,Values='$vpc | grep VpnGatewayId
###OLD###    aws ec2 describe-network-interfaces --filters 'Name=vpc-id,Values='$vpc | grep NetworkInterfaceId###OLD###
###OLD###

###OLD###    printf "%s\n" "Deleting VPC: ${aws_vpc_ids[$i]}  (hopefully)"
###OLD###    aws ec2 delete-vpc --vpc-id ${aws_vpc_ids[$i]}
###OLD###  fi
###OLD###  printf "%s\n" "---"
###OLD###done###OLD###

###OLD####the EKS cluster should already have been deleted  (in reality it is sometimes not)
###OLD###aws_eks_clusters=(`eksctl get clusters -o json | jq -r '.[].name'`)
###OLD###for i in "${!aws_eks_clusters[@]}"; do
###OLD###  printf "%s" "cluster $i =  ${aws_eks_clusters[$i]}.........."
###OLD###  if [[ "${aws_eks_clusters[$i]}" =~ "${AWS_PROJECT}"  && "${aws_eks_clusters[$i]}" =~ "Pipeline" ]]; then
###OLD###      printf "%s\n" "Deleting EKS cluster: ${AWS_PROJECT}"
###OLD###      if [ -s  "${AWS_PROJECT}EksCluster.yml" ]; then
###OLD###        #eksctl delete cluster -f ${AWS_PROJECT}EksCluster.yml
###OLD###        eksctl delete cluster ${AWS_PROJECT}
###OLD###        sleep 30  #giving the delete cluster process a bit more time
###OLD###      else
###OLD###        printf '%s \n' "PANIC: eks cluster with name ${AWS_PROJECT} exists, but file \"${AWS_PROJECT}EksCluster.yml\" does not"
###OLD###        printf '%s \n' "This situation should not exist.  Manual cleanup is required"
###OLD###      fi
###OLD###  else
###OLD###      printf "%s\n" ""
###OLD###  fi
###OLD###done###OLD###
###OLD###

###OLD###printf "%s\n" "Deleting CloudFormation EKS Stack"
###OLD###aws_stack=""
###OLD###aws_stacks=(`aws cloudformation describe-stacks --output json --region $AWS_REGION| jq -r '.Stacks[].StackName'` )
###OLD###for i in "${!aws_stacks[@]}"; do
###OLD###  # printf "%s\n" "stack $i =  ${aws_stacks[$i]}"
###OLD###  if [[ "${aws_stacks[$i]}" =~ "eksctl-${AWS_PROJECT}-cluster" ]]; then
###OLD###    printf "%s\n" "Deleting CloudFormation Stack:  ${aws_stacks[$i]}"
###OLD###    printf "%s\n" "Please be patient, this can take up to 30 minutes... (started at:`date`)"
###OLD###    aws cloudformation delete-stack --stack-name ${aws_stacks[$i]} --region ${AWS_REGION}
###OLD###    aws cloudformation wait stack-delete-complete --stack-name ${aws_stacks[$i]}  --region ${AWS_REGION}
###OLD###  fi
###OLD###done###OLD###
###OLD###
###OLD###

###OLD####cleanup codepipelineartifactbuckets
###OLD###buckets=(`aws s3api list-buckets --region ${AWS_REGION}| jq -r '.Buckets[].Name' ` )
###OLD###for i in "${!buckets[@]}"; do
###OLD###  #printf '%s\n' "Bucket ${i} = ${buckets[${i}]}"
###OLD###  if [[ "${buckets[${i}]}" =~ "codepipelineartifact" &&  "${buckets[${i}]}" =~ "${AWS_PROJECT}" ]]; then
###OLD###      printf "%s\n"  "Deleting codepipelineartifactbucket: ${buckets[${i}]}"
###OLD###      aws s3 rb s3://${buckets[${i}]} --force
###OLD###      #aws s3api  delete-bucket  --bucket ${buckets[$i]}  --region ${AWS_REGION}
###OLD###  fi
###OLD###done###OLD###

###OLD####cleaning up local files
###OLD###[ -e ${AWS_PROJECT}EksCluster.yml ] && rm ${AWS_PROJECT}EksCluster.yml
###OLD###[ -e ${AWS_PROJECT}${APP1}Pipeline.yml ] && rm ${AWS_PROJECT}${APP1}Pipeline.yml
###OLD###[ -e ${AWS_PROJECT}${APP2}Pipeline.yml ] && rm ${AWS_PROJECT}${APP2}Pipeline.yml
###OLD###[ -e ${AWS_PROJECT}${APP3}Pipeline.yml ] && rm ${AWS_PROJECT}${APP3}Pipeline.yml
###OLD###[ -e req.conf ] && rm req.conf
###OLD###[ -e k8s.key ] && rm k8s.key
###OLD###[ -e k8s.crt ] && rm k8s.crt
###OLD###[ -e overrides.yml ] && rm overrides.yml
###OLD###[ -e cloudOneCredentials ] && rm cloudOneCredentials
###OLD####echo About to delete ~/environment/${APP1}/

###OLD###

###OLD###AWS_PROJECT="cloudone03"
###OLD####TODO: delete Role(-s)
###OLD###printf "%s\n" "Deleting Roles and Instance-Profiles"
###OLD###AWS_ROLES=(`aws iam list-roles | jq -r '.Roles[].RoleName ' | grep ${AWS_PROJECT} `)
###OLD###for i in "${!AWS_ROLES[@]}"; do
###OLD###  if [[ "${AWS_ROLES[$i]}" =~ "${AWS_PROJECT}" ]]; then
###OLD###     printf "%s\n" "Role $i =  ${AWS_ROLES[$i]}.........."
###OLD###     #printf "%s\n" "Getting AWS_POLICIES"
###OLD###     AWS_POLICIES=(`aws iam list-role-policies --role-name ${AWS_ROLES[$i]} | jq -r '.PolicyNames[]'`)
###OLD###     aws iam list-role-policies --role-name ${AWS_ROLES[$i]}
###OLD###     printf "%s\n" "AWS_POLICIES= $AWS_POLICIES"
###OLD###     for j in "${!AWS_POLICIES[@]}"; do
###OLD###       printf "%s\n" "  Policy $j =  ${AWS_POLICIES[$j]}"
###OLD###        aws iam detach-role-policy --role-name ${AWS_ROLES[$i]} --policy-name ${AWS_POLICIES[$j]}
###OLD###        aws iam delete-role-policy --role-name ${AWS_ROLES[$i]} --policy-name ${AWS_POLICIES[$j]}
###OLD###     done
###OLD###     #printf "%s\n" "Getting instance Profiles"
###OLD###     #printf "%s\n" "Analyzing Instance Profiles for Role: ${AWS_ROLES[$i]}"
###OLD###     AWS_PROFILES=(`aws iam list-instance-profiles-for-role --role-name ${AWS_ROLES[$i]} | jq -r '.InstanceProfiles[].InstanceProfileName'`)
###OLD###     printf "%s\n" "AWS_PROFILES = $AWS_PROFILES"
###OLD###     for k in "${!AWS_PROFILES[@]}"; do
###OLD###       printf "%s\n" "  Profile $k =  ${AWS_PROFILES[$k]}"
###OLD###       aws iam remove-role-from-instance-profile --role-name ${AWS_ROLES[$i]} --instance-profile-name ${AWS_PROFILES[$j]}
###OLD###       aws iam delete-instance-profile --instance-profile-name ${AWS_PROFILES[$j]}
###OLD###     done
###OLD###     aws iam delete-role  --role-name ${AWS_ROLES[$i]}
###OLD###  fi
###OLD###done
###OLD###aws iam list-roles | jq -r '.Roles[].RoleName ' | grep cloudone###OLD###

###OLD####TODO: delete Policy
