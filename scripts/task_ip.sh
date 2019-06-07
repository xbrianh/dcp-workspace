#!/bin/bash
set -euo pipefail

task=$1
resp=$(aws ecs describe-tasks --cluster default --tasks ${task})
network_interface_id=$(echo ${resp} | jq -r '.tasks[].attachments[].details[] | select(.name=="networkInterfaceId") | .value')
aws ec2 describe-network-interfaces --network-interface-ids ${network_interface_id} | jq -r .NetworkInterfaces[].Association.PublicIp
