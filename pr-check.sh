#!/bin/sh

prnumber=$1 || exit 128

topdir=/Users/$(whoami)/alice

cleanup() {
    cd $topdir/alo || return 1
    git checkout master || return 2
    git branch -D pr$prnumber || return 3
    return 0
}

echo "here i am $@"
cd $topdir/alo || exit 1
if [ -d .git ]; then
  echo "already a git there. perfect"
else
  echo "cloning mrrtf/alo"
  git clone https://github.com/mrrtf/alo . || exit 2
fi

cd $topdir/alidist || exit 10
if [ -d .git ]; then
  echo "already a git there. perfect"
  git fetch --all || exit 11
  git pull || exit 12
else
  echo "cloning alisw/alidist"
  git clone https://github.com/alisw/alidist . || exit 20
fi

cd $topdir/alo
git fetch origin pull/$prnumber/head:pr$prnumber || exit 3
git checkout pr$prnumber || exit 4
cd ..
aliBuild analytics off
aliBuild --defaults alo build alo
if [ $? -ne 0 ]; then
    cleanup
    exit 7
fi

cleanup || exit 8

exit 0
