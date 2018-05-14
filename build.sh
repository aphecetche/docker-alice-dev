#!/bin/sh

# build some (possibly derived) images
# by adding the current user to it

la_build()
{
  local baseimage=$1

    docker build -f Dockerfile.$baseimage -t $baseimage-user . \
    --build-arg userName=$userName \
    --build-arg userId=$UID \
    --build-arg userGroupId=$userGroupId \
    --build-arg userGroup=$userGroup \
    --pull 
}

userName=$(whoami)
userGroup=$(id -gn $userName)
userGroupId=$(id -g $userName)

la_build centos7-ali-core

