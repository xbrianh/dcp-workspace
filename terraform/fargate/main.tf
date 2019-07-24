data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  common_tags = "${map(
    "managedBy" , "terraform",
    "Name"      , "bhannafi-fargate-test",
    "project"   , "dcp",
    "env"       , "dev",
    "service"   , "dss",
    "owner"     , "bhannafi@ucsc.edu"
  )}"
}

resource "aws_iam_role" "task_executor" {
  name = "bhannafi-fargate-test-executor"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ecs.amazonaws.com",
          "ecs-tasks.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_executor_ecs" {
  role = "${aws_iam_role.task_executor.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "query_runner" {
  name = "bhannafi-fargate-test-runner"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "query_runner" {
  name = "bhannafi-fargate-test-runner"
  role = "${aws_iam_role.query_runner.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "tag:GetTagKeys",
        "tag:GetResources",
        "tag:GetTagValues",
        "cloudwatch:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

resource "aws_ecs_task_definition" "dcp-workspace" {
  family = "bhannafi-fargate-test"
  execution_role_arn = "${aws_iam_role.task_executor.arn}"
  task_role_arn = "${aws_iam_role.query_runner.arn}"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "256"
  memory = "512"
  container_definitions = <<DEFINITION
[
  {
    "family": "bhannafi-fargate-test",
    "name": "bhannafi-fargate-test",
    "image": "xbrianh/workspace"
  }
]
DEFINITION
  tags = "${local.common_tags}"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  count             = 3
  vpc_id            = "${data.aws_vpc.default.id}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  default_for_az    = true
}

output "default_vpc_id" {
  value = "${data.aws_vpc.default.id}"
}

output "subnets" {
  value = "${data.aws_subnet.default.*.id}"
}
