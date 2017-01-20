#
# some utility functions to work with ALICE related containers
#
#
# the basis for all this is a naming convention for the directories on
# the local machine or within the container(s)
#
# $HOME/alicesw/runN/context/what
#
# where N = 2 or 3
# what = AliRoot, O2 (case sensitive)
# context is used to group dev environments (e.g. o2 dev with AliceO2, FairRoot, AliRoot checked-out
# locally vs o2 ref where only AliceO2 is checked-out)
#
# also, the built stuff is kept in docker volumes named vc_runN_sw
# (expected to be mounted under $HOME/alicesw/runN/sw directory in
# the container(s))
#
# For instance :
#
# /Users/laurent/alicesw/run3
# ├── aliroot-ed-detector-experts
# │   ├── AliRoot
# ├── aliroot-feature-muonhlt
# │   ├── AliRoot
# ├── o2-dev
# │   ├── FairRoot
# │   ├── O2
# ├── root6
# │   ├── ROOT
# └── sw
#     ├── BUILD
#     ├── INSTALLROOT
#     ├── MIRROR
#     ├── SOURCES
#     ├── SPECS
#     ├── TARS
#     └── osx_x86-64
#

ali_start_container() {

    # start a detached aliroot container, in x11 mode
    #
    # on input a number of bind mounted directories (ro) :
    # - .globus to get the certificate for alien-token-init
    # - $what (either AliRoot or AliPhysics) to get the relevant source code
    # - repos/$what as the previous one is a worktree from this one
    #
    # on "output" a single docker-managed volume containing the build
    # and install directories (vc_run2_sw)
    # (where vc_ denotes a Volume Container)
    #

    export ALI_RUN=$1
    export ALI_CONTEXT=$2
    export ALI_WHAT=$3

    local detach="--rm"
    local exec="/bin/bash"

    if [ $# -ge 4 ]; then
        option=$4
        if [ "$option" = "--detach" ]; then
            detach="--detach"
            exec=""
            shift
        fi
    fi 

    shift 3

    echo "detach=$detach exec=$exec"

    docker_run_withX11 --interactive --tty $detach \
        --name "$ALI_CONTEXT" \
        --env "ALI_WHAT=$ALI_WHAT" \
        --env "ALI_VERSION=$ALI_VERSION" \
        --env "ALI_CONTEXT=$ALI_CONTEXT" \
        --volume vc_${ALI_RUN}_sw:$HOME/alicesw/${ALI_RUN}/sw \
        --volume $HOME/.globus:$HOME/.globus:ro \
        --volume $HOME/alicesw/${ALI_RUN}/${ALI_CONTEXT}/${ALI_WHAT}:$HOME/alicesw/${ALI_RUN}/${ALI_CONTEXT}/${ALI_WHAT}:ro \
        --volume $HOME/alicesw/repos/${ALI_WHAT}:$HOME/alicesw/repos/${ALI_WHAT}:ro \
        $@ \
        centos7-ali-core \
        $exec

    # the image used, centos7-ali-core, is built from aphecetche/centos7-ali-core, by adding
    # the local user as the default user (instead of root), so we can matching UID/GUI on
    # the filesystem. See github.com/aphecetche/docker-alice-dev
}

ali_setup_tmux() {

    # setup, if it does not exist yet, a window
    # in the current tmux session with the following layout :
    #
    # ---------------------------------------
    # |                  |                  |
    # |                  |                  |
    # |                  | build dir in     |
    # |                  | docker container |
    # |                  | (pane 2)         |
    # |                  |                  |
    # |  local dir       |-------------------
    # |  (pane 1)        |                  |
    # |                  | exec dir in      |
    # |                  | docker container |
    # |                  | (pane 3)         |
    # |                  |                  |
    # ---------------------------------------
    #

    local run=$1
    local context=$2
    local what=$3
    local dir=$HOME/alicesw/$run/$context
    local wname=$context
    local pane_localedit=1
    local pane_build=2
    local pane_exec=3

    tmux new-window -n $wname
    tmux split-window -h -t $wname 
    tmux split-window -v -t $wname.2

    tmux send-keys -t $wname.$pane_exec "cd $dir; docker exec -it $wname /bin/bash" enter
    tmux send-keys -t $wname.$pane_build "cd $dir; docker exec -it $wname /bin/bash" enter
    tmux send-keys -t $wname.$pane_localedit "cd $dir/$what" enter

    tmux send-keys -t $wname.$pane_build "cd /alicesw/sw/BUILD/$what-latest-$version/$what" enter

    for pane in 1 2 3; do
        tmux send-keys -t $wname.$pane "clear" enter
    done

    tmux send-keys -t $wname.$pane_build "pwd" enter
}

ali_docker() {
    #
    # run a container with the source locally on the Mac
    # and the build/install in a managed docker container
    # 
    run=${1:="run3"}

    context=${2:="o2-dev"}

    what=${3:="O2"}

    shift 3

    if ! test -d $HOME/alicesw/$run/$context/$what; then
        echo "Directory $HOME/alicesw/$run/$context/$what does not exists !"
        echo "The directories I know of in $run are :"
        ls -d $HOME/alicesw/$run/*
        return
    fi

    if ! dexist "$context"; then
        # start a new container 
        echo "trailing arguments passed as is : $@"
        ali_start_container $run $context $what --detach $@
        sleep 2
    fi

    # setup the tmux layout if needed
    if [[ $TMUX ]]; then
        ali_setup_tmux $run $context $what
    else
        # simply connect to the container
        docker exec -it $context /bin/bash
    fi
}

ali_vim() {

    docker run -it --rm -v "$PWD:$PWD" \ 
    --volume vc_${ALI_RUN}_sw:/home/$UID/alicesw/${ALI_RUN}/sw \
        --volume $HOME/alicesw/${ALI_RUN}/${ALI_CONTEXT}/${ALI_WHAT}:$HOME/alicesw/${ALI_RUN}/${ALI_CONTEXT}/${ALI_WHAT}:ro \
        -w "$PWD" -p 1337:1337 alpine-vim $@
}

ali_o2() {

    ali_docker run3 o2-dev O2
}

ali_physics() {

    ali_docker run2 aliphysics-master AliPhysics
}

ali_o2_ref() {

    ali_docker run3 o2-ref O2 
}

ali_cvmfs() {

    # first argument (required) is the XXX::VVV string to be used
    # to issue the "alienv enter XXX::VVV" command at the
    # container startup
    #
    # remaining arguments are passed to the docker command itself
    # and can be used e.g. to bind mount more volumes
    #
    version=$1
    if [ $# -gt 0 ]; then
        shift
    fi

    docker_run_withX11 --rm --interactive --tty --privileged \
        -v $HOME/.globus:/root/.globus \
        -v $HOME/.rootrc:/root/.rootrc \
        $@ aphecetche/centos7-ali-cvmfs $version
}

ali_root6() 
{
    ali_docker run3 root6 ROOT
}
