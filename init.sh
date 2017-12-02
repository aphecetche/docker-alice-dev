#
# some utility functions to work with ALICE related containers
#
#
# the basis for all this is a naming convention for the directories on
# the local machine or within the container(s)
#
# $HOME/alice/context/what
#
# what = AliRoot, O2 (case sensitive)
# context is used to group dev environments (e.g. o2 dev with AliceO2, FairRoot, AliRoot checked-out
# locally vs o2 ref where only AliceO2 is checked-out)
#
# the output sw directory below is assumed to be a docker volume by default
#
# For instance :
#
# /Users/laurent/alice
# ├── ali-master
# │   ├── AliRoot
# │   ├── alidist
# ├── ali-physics-master
# │   ├── AliPhysics
# │   ├── alidist
# ├── o2-dev
# │   ├── AliRoot
# │   ├── FairRoot
# │   ├── O2
# │   ├── alidist
# │   ├── alo
# └── sw
#     ├── BUILD
#     ├── INSTALLROOT
#     ├── MIRROR
#     ├── SOURCES
#     ├── SPECS
#     ├── TARS
#     └── osx_x86-64

ALI_SW_VOLUME="vc_alice_sw"
#ALI_SW_VOLUME="$HOME/alice/sw"

ali_assert_sw_volume()
{
    if [ "$ALI_SW_VOLUME" = "vc_alice_sw" ]; then
        docker volume create --name $ALI_SW_VOLUME
    fi
}

ali_start_container() {

    # start a detached aliroot container, in x11 mode
    #
    # on input a number of bind mounted directories (ro) :
    # - .globus to get the certificate for alien-token-init
    # - $what (either AliRoot or AliPhysics) to get the relevant source code
    # - alidist (to avoid having to mount the context directory rw in the container)
    #

   ali_assert_sw_volume

    export ALI_CONTEXT=$1
    export ALI_WHAT=$2

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
        --env "USEDEVTOOLSET=1" \
        --volume $ALI_SW_VOLUME:$HOME/alice/sw \
        --volume $HOME/.globus:$HOME/.globus:ro \
        --volume $HOME/alice/${ALI_CONTEXT}/${ALI_WHAT}:$HOME/alice/${ALI_CONTEXT}/${ALI_WHAT}:ro \
        --volume $HOME/alice/${ALI_CONTEXT}/alidist:$HOME/alice/${ALI_CONTEXT}/alidist:ro \
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

    local context=$1    
    local what=$2
    local dir=$HOME/alice/$context
    local wname=$context
    local pane_localedit=1
    local pane_build=2
    local pane_exec=3

    tmux new-window -n $wname
    tmux split-window -h -t $wname 
    tmux split-window -v -t $wname.2

    tmux send-keys -t $wname.$pane_exec "cd $dir; docker exec -it $wname /bin/bash" enter
    tmux send-keys -t $wname.$pane_build "cd $dir; docker exec -it $wname /bin/bash" enter
    tmux send-keys -t $wname.$pane_localedit "cd $dir/$what; export ALI_WHAT=$what; export
    ALI_CONTEXT=$context; " enter

    tmux send-keys -t $wname.$pane_build "cd /alice/sw/BUILD/$what-latest-$version/$what" enter

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
    context=${1:="o2-dev"}

    what=${2:="O2"}

    shift 2

    if ! test -d $HOME/alice/$context/$what; then
        echo "Directory $HOME/alice/$context/$what does not exists !"
        echo "The directories I know of in :"
        ls -d $HOME/alice/*
        return
    fi

    if ! dexist "$context"; then
        # start a new container 
        echo "trailing arguments passed as is : $@"
        ali_start_container $context $what --detach $@
        sleep 2
    fi

    # setup the tmux layout if needed
    if [[ $TMUX && $USE_TMUX ]]; then
        ali_setup_tmux $context $what
    else
        # simply connect to the container
        docker exec -it $context /bin/bash
    fi
}

ali_vim() {

    docker run -it --rm -v "$PWD:$PWD" \ 
    --volume $ALI_SW_VOLUME:/home/$UID/alice/sw \
        --volume $HOME/alice/${ALI_CONTEXT}/${ALI_WHAT}:$HOME/alice/${ALI_CONTEXT}/${ALI_WHAT}:ro \
        -w "$PWD" -p 1337:1337 alpine-vim $@
}

ali_o2() {

    ali_docker o2-dev O2 \
        -v $HOME/alice/o2-dev/FairRoot:$HOME/alice/o2-dev/FairRoot:ro \
        -v $HOME/alice/o2-dev/DDS:$HOME/alice/o2-dev/DDS \
        -v$(pwd):/data

    # note that DDS can not be mounted read-only as some version file is generated in the
    # source directory (under etc/version) during install stage...
}

ali_alo() {

    ali_docker o2-dev alo --detach \
        -v $HOME/alice/o2-dev/AliRoot:$HOME/alice/o2-dev/AliRoot:ro \
        -v $HOME/alice/o2-dev/O2:$HOME/alice/o2-dev/O2:rw \
        -v$(pwd):/data

    # note that DDS can not be mounted read-only as some version file is generated in the
    # source directory (under etc/version) during install stage...
    # same note for O2 just because of compile_commands.json ...
}

ali_alo_pr_check() {
        docker volume create --name vc_alice_alo_src
        docker volume create --name vc_alice_alidist_src
    docker run --env PATH=$PATH:/home/laurent -it --rm \
        -v vc_alice_sw:$HOME/alice/sw \
        -v vc_alice_alo_src:$HOME/alice/alo \
        -v vc_alice_aldist_src:$HOME/alice/alidist \
        centos7-ali-core devtoolset.sh "pr-check.sh $1"
        # centos7-ali-core devtoolset.sh bash
}

ali_physics() {

    ali_docker aliphysics-master AliPhysics
}

ali_o2_ref() {

    ali_docker o2-ref O2 
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
    ali_docker root6 ROOT
}
