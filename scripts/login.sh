#!/bin/bash
set -euo pipefail
key="${DCP_WORKSPACE_HOME}/image/key"
mosh --ssh="ssh -i ${key} -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' -o 'LogLevel ERROR'" dcp@${1}
# ssh -i key -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" -o "LogLevel ERROR" dcp@${1}
