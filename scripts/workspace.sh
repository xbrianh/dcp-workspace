#!/bin/bash
set -euo pipefail

git config user.name > /dev/null || { echo 'Please configure a git user name with `git config --global user.name _my_git_username_`'; exit 1; }
git config user.email > /dev/null || { echo 'Please configure a git user email with `git config --global user.email _my_git_email_`'; exit 1; }

export DEPLOYMENT=${1:-dev}
workspace_name="dcp-workspace-${DEPLOYMENT}"
wid=$(docker ps -a --latest --filter "name=${workspace_name}" --format="{{.ID}}")

if [[ -z $wid ]]; then
    config=$(cat ${DCP_WORKSPACE_HOME}/config.json | jq -c .)
    config=$(echo ${config} | jq --arg name "$(git config user.name)" -c '.git.name=$name')
    config=$(echo ${config} | jq --arg email "$(git config user.email)" -c '.git.email=$email')
    
	${DCP_WORKSPACE_HOME}/scripts/start_fargate.py "${config}"
	DCP_WORKSPACE_CONTAINER_PORT=22
	# source ${DCP_WORKSPACE_HOME}/scripts/start_local.sh "$(echo ${config} | sed 's/"/\\"/g')"

    for name in ".git-credentials" ".aws" ".google"; do
        filename=${HOME}/${name}
        if [[ -d $filename || -f $filename ]]; then
            echo "Found $filename, copying into container"
            scp -i ${DCP_WORKSPACE_HOME}/image/key -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -o "LogLevel ERROR" -P ${DCP_WORKSPACE_CONTAINER_PORT} -r $filename dcp@${DCP_WORKSPACE_CONTAINER_HOST}:~
        fi
    done
fi

docker start ${workspace_name} || true
docker exec -it $workspace_name /bin/bash
