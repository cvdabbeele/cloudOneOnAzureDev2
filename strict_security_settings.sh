
STARTDIR=`pwd`
cd ~/apps/c1-app-sec-moneyx
sed -i 's/": 300/": 0/g' azure-pipelines.yml

 echo " "  >>README.md  && git add . && git commit -m "strict security settings"  && git push  --set-upstream origin master
cd $STARTDIR