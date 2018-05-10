#!/bin/sh

prnumber=$1 || exit 128

what=${2:-alo}

topdir=/Users/$(whoami)/alice

cleanup() {
    cd $topdir/$what || return 1
    git checkout master || return 2
    git branch -D pr$prnumber || return 3
    return 0
}

cd $topdir/alo || exit 1
if [ -d .git ]; then
  echo "already a git for alo there. perfect"
else
  echo "cloning mrrtf/alo"
  git clone https://github.com/mrrtf/alo . || exit 2
fi

cd $topdir/O2 || exit 20
if [ -d .git ]; then
  echo "already a git for O2 there. perfect"
else
  echo "cloning AliceO2"
  git clone https://github.com/AliceO2Group/AliceO2 . || exit 22
fi

cd $topdir/alidist || exit 10
if [ -d .git ]; then
  echo "already a git for alidist there. perfect"
  git fetch --all || exit 11
  git pull || exit 12
else
  echo "cloning alisw/alidist"
  git clone https://github.com/alisw/alidist . || exit 20
fi

cd $topdir/$what
git fetch origin pull/$prnumber/head:pr$prnumber || exit 3
git checkout pr$prnumber || exit 4
cd ..
aliBuild analytics off
defaults=$(echo "$what" | tr '[:upper:]' '[:lower:]') 
aliBuild --defaults $defaults build $what
if [ $? -ne 0 ]; then
    cleanup
    exit 7
fi

cleanup || exit 8

exit 0
