#!/bin/bash
set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DCP_WORKSPACE_HOME="$(cd -P "$(dirname "$SOURCE")" && pwd)"

deployment=${1:-dev}
workspace_name="dcp-workspace-${deployment}"
wid=$(docker ps -a --latest --filter "name=${workspace_name}" --format="{{.ID}}")

git config user.name > /dev/null || { echo 'Please configure a git user name with `git config --global user.name _my_git_username_`'; exit 1; }
git config user.email > /dev/null || { echo 'Please configure a git user email with `git config --global user.email _my_git_email_`'; exit 1; }

if [[ -z $wid ]]; then
    docker pull xbrianh/workspace
    
    wid=$(docker run --mount type=bind,source=${DCP_WORKSPACE_HOME}/shared,target=/home/dcp/shared --name $workspace_name -it --env DEPLOYMENT=$deployment -d xbrianh/workspace)
    
    docker exec -it $wid git config --global credential.helper store
    for name in ".git-credentials" ".aws" ".google"; do
        filename=${HOME}/${name}
        if [[ -d $filename || -f $filename ]]; then
            echo "Found $filename, copying into container"
            docker cp $filename $wid:/home/dcp
        fi
    done
    
    for name in $DCP_WORKSPACE_HOME/dotfiles/*; do
        docker cp $name $wid:/home/dcp/.$(basename $name)
    done

    docker exec -it $wid git config --global credential.helper store
    docker exec -it $wid git config --global user.name $(git config user.name)
    docker exec -it $wid git config --global user.email $(git config user.email)
    
    docker cp ${DCP_WORKSPACE_HOME}/startup $wid:/home/dcp/.startup
    docker exec -it -u 0 $wid chown -R dcp:dcp /home/dcp
    docker exec -it $wid /home/dcp/.startup/startup.sh
fi

docker start ${wid} || echo
docker exec -it $wid /bin/bash
