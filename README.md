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
- execute the `build.sh` script to generate a local image (based on aphecetche/centos7-ali-core) with the local
    user
 
## Usage 

- `ali_docker o2-dev O2` wil start a `o2-dev` container or connect to it if it already exists. Will also setup some tmux windows if under tmux and environment variable USE_TMUX is set.
- `ali_start_container o2-dev O2` will create *and* enter the `o2-dev` container.
- `ali_start_container o2-dev O2 --detach` will just create the container

Convenience shortcuts are defined, e.g `ali_alo` creates a container to develop
[alo](https://github.com/aphecetche/alo).


# Notes on performance

The performance of using files from bind mounts does not seem to be perfectly adequate as far as
performance goes. It seems `osxfs` is not yet up to the task... Hopefully that will improve in the future. 

For the input volume(s) (the one(s) containing the source files) there is nothing that can be done except for waiting
for Docker to work faster ;-)

For the output volume one option is to use a docker volume (i.e. have the build artifacts store within the Linux VM, not
on the Mac host). 

Timing the difference for a compilation ? => ( insert numbers here )
