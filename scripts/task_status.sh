#!/bin/bash
set -euo pipefail
task=${1}
resp=$(aws ecs describe-tasks --cluster default --tasks ${task})
status=$(echo ${resp} | jq -r '.tasks[].lastStatus')
if [[ ${status} != "" ]]; then
    echo ${status}
else
    echo MISSING
fi
