STARTDIR=`pwd`

cd ~/apps/c1-app-sec-moneyx
sed -i 's/": 0/": 300/g' azure-pipelines.yml
 echo " "  >>README.md  && git add . && git commit -m "relaxed security settings"  && git push  --set-upstream origin master
cd $STARTDIR