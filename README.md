Some utilities to work with docker containers to develop Alice software

Typical usage would be :

- execute (once) the `build.sh` script to generate a local image (based on aphecetche/centos7-ali-core) with the local
    user
- `. ./init.sh` to defines the bash functions to be used (below)
- `ali_docker run3 o2-dev O2` wil start a `o2-dev` container or connect to it if it already exists. Will also setup some tmux windows if under
    tmux.
- `ali_start_container run3 o2-dev O2 --detach` as above but without the tmux setup.
- `ali_start_container run3 o2-dev O2` will create *and* enter the `o2-dev` container.

See `init.sh` comments for more information.
