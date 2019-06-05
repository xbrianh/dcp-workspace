#!/usr/bin/env python
import os
import sys
import time
import json
from subprocess import run, PIPE

import boto3

ecs = boto3.client("ecs")
home = os.environ['DCP_WORKSPACE_HOME']
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
    }
)

task = resp['tasks'][0]['taskArn'] 
print(task)

for _ in range(60):
    status = resp['tasks'][0]['lastStatus']
    if "RUNNING" == status:
        break
    elif "STOPPED" == status or "DEPROVISIONING" == status:
        raise Exception("Failed to start Fargate container")
    else:
        time.sleep(5)
        resp = ecs.describe_tasks(cluster="default", tasks=[task])
        print(resp['tasks'][0]['lastStatus'])
else:
    raise Exception("Failed to start Fargate container")

print(resp['tasks'][0]['attachments'])
