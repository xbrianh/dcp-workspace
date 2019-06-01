#!/bin/bash
set -euo pipefail

output=$(aws ecs stop-task --cluster default --task $1)

echo "Last status:"
echo ${output} | jq -r .task.lastStatus
echo
echo "Desired status:"
echo ${output} | jq -r .task.desiredStatus
