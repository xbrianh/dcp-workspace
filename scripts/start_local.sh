#!/bin/bash
set -euo pipefail

config=$1

docker pull xbrianh/workspace
docker run --mount type=bind,source=${DCP_WORKSPACE_HOME}/shared,target=/home/dcp/shared \
	   --name $workspace_name -it --env DEPLOYMENT=${DEPLOYMENT} -p 22 -d \
	   --env DEPLOYMENT=${DEPLOYMENT} \
	   xbrianh/workspace /home/dcp/bin/entrypoint.sh "${config}"

export host="localhost"
export port=$(docker port ${workspace_name} 22 | cut -d':' -f2)

for i in {1..15}; do
    if ssh -p ${port} -i ${DCP_WORKSPACE_HOME}/image/key -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' -o 'LogLevel ERROR' dcp@${host} > /dev/null true 2>&1; then
        break
    else
        echo "Waiting for sshd to stand up"
        sleep 1
    fi
done

export DCP_WORKSPACE_CONTAINER_HOST=${host}
export DCP_WORKSPACE_CONTAINER_PORT=${port}
