
ls /home/$(whoami)/alicesw/$ALI_RUN/sw/slc* > /dev/null 2>&1 && myhome=/home/$(whoami) || myhome=/Users/$(whoami)

cd $myhome/alicesw/$ALI_RUN
aliBuild analytics on
ALICE_WORK_DIR=$(pwd)/sw; eval "`alienv shell-helper`"

