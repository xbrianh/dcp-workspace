#!/bin/bash
set -euo pipefail

name="ssh-server"

old_wid=$(docker ps -a --latest --filter "name=${name}" --format="{{.ID}}")
docker stop ${old_wid} > /dev/null 2>&1 || true
docker rm ${old_wid} > /dev/null 2>&1 || true

wid=$(docker run -d -P --name ${name} -d xbrianh/workspace)
echo ${wid}
docker port ${name} 22
