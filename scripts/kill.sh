#!/bin/bash
set -euo pipefail

deployment=${1:-dev}
workspace_name="dcp-workspace-${deployment}"

if [[ ${DCP_WORKSPACE_PLATFORM} == local ]]; then
    wid=$(docker ps -a --latest --filter "name=${workspace_name}" --format="{{.ID}}")
    if [[ -z $wid ]]; then
        exit 1
    fi
    docker kill $wid > /dev/null 2>&1 || :
    docker rm $wid
else
    task=$(cat ${DCP_WORKSPACE_HOME}/.fargate_status.json | jq -r --arg name ${workspace_name} '.[$name]')
    if [[ $task == "null" ]]; then
        exit 1
    fi
    ${DCP_WORKSPACE_HOME}/scripts/stop_task.sh ${task}
    cat ${DCP_WORKSPACE_HOME}/.fargate_status.json | jq -r --arg name ${workspace_name} 'del(.[$name])' | sponge ${DCP_WORKSPACE_HOME}/.fargate_status.json
fi
