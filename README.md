# What's in there

Some utilities to work with docker containers to develop Alice software

## Executive summary

Use `ali_alo` to enter a container to develop `alo`.

Use `ali_alo_pr_check [prnumber]` to check compilation of `alo` github pull request number [prnumber].

Use `ali_o2_pr_check [prnumber] O2` to check compilation of `O2` github pull request number [prnumber].

## Installation

- install the [docker tools](https://github.com/aphecetche/scripts/tree/master/docker)
- copy the `docker-alice-dev.modulefile` to `$HOME/privatemodulefiles/docker-alice-dev`
- module load docker-alice-dev
- execute the `build.sh` script to generate a local image (based on aphecetche/centos7-ali-core) with the local user. The `aphecetche/centos7-ali-core` is pulled from Docker hub unless the option `local` is passed to the `build.sh` script.
 
## Usage 

Basic command is `ali_start_container` :

```
ali_start_container --help
        --name specify the name of the container
        --volume-sw the name of the volume or directory that will hold the build artifacts
        --volume-o2 the name of the volume or directory that contains O2 source
        --volume-alo the name of the volume or directory that contains alo source
        --volume-alidist the name of the volume or directory that contains alidist source
        --rm the container will be destroyed automatically on exit
        --detach starts the container in detached mode
        --globus mounts the /Users/laurent/.globus directory into the container
        --exec the command to execute (/bin/bash by default) in the container
````

`ali_start_container --name o2-dev --volume-o2 /some/dir/with/o2/source` --volume-sw vc_alice_sw will create *and* enter the `o2-dev` container.

`ali_start_container --name o2-dev --volume-o2 /some/dir/with/o2/source` --volume-sw vc_alice_sw--detach` will just create the container

Some convenience shortcuts are defined, e.g `ali_alo` creates a container to develop
[alo](https://github.com/aphecetche/alo).


# Notes on performance

The performance of using files from bind mounts does not seem to be perfectly adequate as far as
performance goes. It seems `osxfs` is not yet up to the task... Hopefully that will improve in the future. 

For the input volume(s) (the one(s) containing the source files) there is nothing that can be done except for waiting for Docker to work faster ;-)

For the output volume one option is to use a docker volume (i.e. have the build artifacts store within the Linux VM, not on the Mac host). 

Timing the difference for a compilation ? => ( insert numbers here )

