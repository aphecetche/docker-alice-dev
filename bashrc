
myhome=/home/$(whoami)

if [ -d /Users/ ]; then
    myhome=/Users/$(whoami)
fi

cd $myhome
export WORK_DIR="$myhome/alicesw/$ALI_RUN/sw"

cd $WORK_DIR
cd ../$ALI_CONTEXT

aliBuild analytics on

ALICE_WORK_DIR=$WORK_DIR; eval "`alienv shell-helper`"
