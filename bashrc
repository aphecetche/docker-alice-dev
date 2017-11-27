if [ -n "$USEDEVTOOLSET" ]; then
    unset USEDEVTOOLSET && scl enable rh-git29 devtoolset-6 bash
fi

ls /home/$(whoami)/alice/sw/slc* > /dev/null 2>&1 && myhome=/home/$(whoami) || myhome=/Users/$(whoami)

cd $myhome/alice
aliBuild analytics on
export ALIBUILD_WORK_DIR=$(pwd)/sw; eval "`alienv shell-helper`"

