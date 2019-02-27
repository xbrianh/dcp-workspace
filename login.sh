#!/bin/bash
set -euo pipefail

deployment=${1:-dev}
workspace_name="dcp-workspace-${deployment}"

dcp_workspace_id=$(docker ps --latest --filter "name=${workspace_name}" --format="{{.ID}}")
if [[ -z $dcp_workspace_id ]]; then
    exit 1
fi
docker exec -it $dcp_workspace_id /bin/bash
