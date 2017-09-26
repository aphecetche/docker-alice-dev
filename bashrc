
ls /home/$(whoami)/alice/sw/slc* > /dev/null 2>&1 && myhome=/home/$(whoami) || myhome=/Users/$(whoami)

cd $myhome/alice
aliBuild analytics on
export ALIBUILD_WORK_DIR=$(pwd)/sw; eval "`alienv shell-helper`"

