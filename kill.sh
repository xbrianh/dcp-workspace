#!/bin/bash
set -euo pipefail

deployment=${1:-dev}
workspace_name="dcp-workspace-${deployment}"
wid=$(docker ps --latest --filter "name=${workspace_name}" --format="{{.ID}}")

if [[ -z $wid ]]; then
    exit 1
fi

docker kill $wid
docker rm $wid
