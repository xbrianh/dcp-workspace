#!/usr/bin/env python
import os
import sys
import time
import json
from subprocess import run, PIPE

import boto3

ecs = boto3.client("ecs")
ec2 = boto3.client("ec2")

config = sys.argv[1]

subnets = run(
    ["terraform", "output", "subnets"],
    cwd=f"{os.environ['DCP_WORKSPACE_HOME']}/terraform/fargate",
    stdout=PIPE,
    stderr=PIPE,
).stdout.decode("utf-8")
security_group = "sg-0ad8c836671c47d8f"

resp = ecs.run_task(
    cluster="default",
    taskDefinition="bhannafi-fargate-test",
    launchType="FARGATE",
    networkConfiguration={
        'awsvpcConfiguration': {
            'subnets': subnets.split(","),
            'securityGroups': [security_group],
            'assignPublicIp': 'ENABLED'
        }
    },
    overrides={
        'containerOverrides': [{
            'name': "bhannafi-fargate-test",
            'command': ["/home/dcp/bin/entrypoint.sh", config],
            'environment': [
                {
                    'name': "DEPLOYMENT",
                    'value': f"{os.environ['DEPLOYMENT']}"
                }
            ]
        }],
    },
)

task = resp['tasks'][0]['taskArn']

filepath=f"{os.environ['DCP_WORKSPACE_HOME']}/.fargate_status.json"
if os.path.isfile(filepath):
    with open(filepath, "r") as fh:
        status = json.loads(fh.read())
else:
    status = dict()
status[os.environ['workspace_name']] = task
with open(filepath, "w") as fh:
    fh.write(json.dumps(status))

print(task)
