#!/bin/bash
set -euo pipefail

config=$1

subnets=$(cd $DCP_WORKSPACE_HOME/terraform/fargate ; terraform output subnets)
security_group="sg-0ad8c836671c47d8f"

overrides=$(jq -n -c --argjson config "${config}" '.command=["/home/dcp/bin/entrypoint.sh", $config]')

output=$(aws ecs run-task --task-definition bhannafi-fargate-test \
  --cluster default \
  --launch-type FARGATE \
  --network-configuration=awsvpcConfiguration="{subnets=[${subnets}],securityGroups=[${security_group}],assignPublicIp=ENABLED}")
  --overrides="${overrides}"
#  --overrides='{"taskRoleArn":"arn:aws:iam::861229788715:role/bhannafi-green-beret"}')

task_arn=$(echo ${output} | jq -r .tasks[].taskArn)
echo ${task_arn}

for i in {1..60}; do
	output=$(aws ecs describe-tasks --cluster default --tasks ${task_arn})
	last_status=$(echo ${output} | jq -r '.tasks[].lastStatus')
	if [[ RUNNING != ${last_status} ]]; then
       echo "Task status is ${last_status}..."
       sleep 5
    else
       break
    fi
done

if [[ ${i} == 60 ]]; then
	echo "failed"
    exit 1
fi

network_interface_id=$(echo ${output} | jq -r '.tasks[].attachments[].details[] | select(.name=="networkInterfaceId") | .value')
host=$(aws ec2 describe-network-interfaces --network-interface-ids ${network_interface_id} | jq -r .NetworkInterfaces[].Association.PublicIp)

export DCP_WORKSPACE_CONTAINER_HOST=${host}
export DCP_WORKSPACE_CONTAINER_PORT=22
