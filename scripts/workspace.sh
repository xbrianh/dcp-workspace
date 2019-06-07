#!/bin/bash
set -euo pipefail

function wait_for_fargate_status() {
    task=$1
	for i in {1..60}; do
		task_status=$(${DCP_WORKSPACE_HOME}/scripts/task_status.sh ${task})
		if [[ RUNNING != ${task_status} ]]; then
	       echo "Task status is ${task_status}..."
	       sleep 5
	    else
	       break
	    fi
	done

    if [[ ${i} == 60 ]]; then
    	echo "failed"
        exit 1
    fi
}

git config user.name > /dev/null || { echo 'Please configure a git user name with `git config --global user.name _my_git_username_`'; exit 1; }
git config user.email > /dev/null || { echo 'Please configure a git user email with `git config --global user.email _my_git_email_`'; exit 1; }

export DEPLOYMENT=${1:-dev}
export workspace_name="dcp-workspace-${DEPLOYMENT}"

if [[ ${DCP_WORKSPACE_PLATFORM} == local ]]; then
    wid=$(docker ps -a --latest --filter "name=${workspace_name}" --format="{{.ID}}")
elif [[ -f ${DCP_WORKSPACE_HOME}/.fargate_status.json ]]; then
    wid=$(cat ${DCP_WORKSPACE_HOME}/.fargate_status.json | jq --arg name ${workspace_name} '.[$name]')
	if [[ ${wid} == "null" ]]; then
        wid=""
    fi
else
    wid=""
fi

if [[ -z $wid ]]; then
    config=$(cat ${DCP_WORKSPACE_HOME}/config.json | jq -c .)
    config=$(echo ${config} | jq --arg name "$(git config user.name)" -c '.git.name=$name')
    config=$(echo ${config} | jq --arg email "$(git config user.email)" -c '.git.email=$email')
	if [[ ${DCP_WORKSPACE_PLATFORM} == fargate ]]; then
	    task=$(${DCP_WORKSPACE_HOME}/scripts/start_fargate.py "${config}")
		echo ${task}
		wait_for_fargate_status ${task}
		export DCP_WORKSPACE_CONTAINER_HOST=$(${DCP_WORKSPACE_HOME}/scripts/task_ip.sh ${task})
	    export DCP_WORKSPACE_CONTAINER_PORT=22
    elif [[ ${DCP_WORKSPACE_PLATFORM} == local ]]; then
	    source ${DCP_WORKSPACE_HOME}/scripts/start_local.sh "$(echo ${config} | sed 's/"/\\"/g')"
    fi

    for name in ".git-credentials" ".aws" ".google"; do
        filename=${HOME}/${name}
        if [[ -d $filename || -f $filename ]]; then
            echo "Found $filename, copying into container"
            scp -i ${DCP_WORKSPACE_HOME}/image/key -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -o "LogLevel ERROR" -P ${DCP_WORKSPACE_CONTAINER_PORT} -r $filename dcp@${DCP_WORKSPACE_CONTAINER_HOST}:~
        fi
    done
fi

if [[ ${DCP_WORKSPACE_PLATFORM} == local ]]; then
    docker start ${workspace_name} || true
    docker exec -it $workspace_name /bin/bash
elif [[ ${DCP_WORKSPACE_PLATFORM} == fargate ]]; then
    key="${DCP_WORKSPACE_HOME}/image/key"
    mosh --ssh="ssh -i ${key} -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' -o 'LogLevel ERROR'" dcp@${DCP_WORKSPACE_CONTAINER_HOST}
fi
