data "template_file" "access-service" {
  template = "${file("task-definitions/access-service.json")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
  }
}

data "template_file" "apigateway" {
  template = "${file("task-definitions/apigateway.json")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
    pm2env      = "${var.pm2_env[var.environment]}"
  }
}

data "template_file" "config" {
  template = "${file("task-definitions/config.json")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
  }
}

data "template_file" "notification-consumer" {
  template = "${file("task-definitions/notification-consumer.json")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
  }
}

data "template_file" "ell" {
  template = "${file("task-definitions/ell.json")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
  }
}

data "template_file" "loyalty" {
  template = "${file("task-definitions/loyalty.json")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
  }
}

data "template_file" "map-service" {
  template = "${file("task-definitions/map-service.json")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
  }
}

data "template_file" "outlet-service" {
  template = "${file("task-definitions/generic-outlet-service.json")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
  }
}

data "template_file" "notification-producer" {
  template = "${file("task-definitions/notification-producer.json")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
  }
}

data "template_file" "retailer-module" {
  template = "${file("task-definitions/retailer-module.json")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
  }
}

data "template_file" "sshd" {
  template = "${file("task-definitions/sshd.json")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
  }
}

data "template_file" "feedback-module" {
  template = "${file("task-definitions/feedback-module.json")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
  }
}

resource "aws_ecs_task_definition" "access-service" {
  family                   = "${var.environment}_access"
  task_role_arn            = "${var.ecs_role_arn}"
  execution_role_arn       = "${var.ecs_role_arn}"
  container_definitions    = "${data.template_file.access-service.rendered}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_task_definition" "apigateway" {
  family                   = "${var.environment}_apigateway"
  task_role_arn            = "${var.ecs_role_arn}"
  execution_role_arn       = "${var.ecs_role_arn}"
  container_definitions    = "${data.template_file.apigateway.rendered}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_task_definition" "config" {
  family                   = "${var.environment}_config"
  task_role_arn            = "${var.ecs_role_arn}"
  execution_role_arn       = "${var.ecs_role_arn}"
  container_definitions    = "${data.template_file.config.rendered}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_task_definition" "notification-consumer" {
  family                   = "${var.environment}_consumer"
  task_role_arn            = "${var.ecs_role_arn}"
  execution_role_arn       = "${var.ecs_role_arn}"
  container_definitions    = "${data.template_file.notification-consumer.rendered}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_task_definition" "ell" {
  family                   = "${var.environment}_ell"
  task_role_arn            = "${var.ecs_role_arn}"
  execution_role_arn       = "${var.ecs_role_arn}"
  container_definitions    = "${data.template_file.ell.rendered}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
}

resource "aws_ecs_task_definition" "loyalty" {
  family                   = "${var.environment}_loyalty"
  task_role_arn            = "${var.ecs_role_arn}"
  execution_role_arn       = "${var.ecs_role_arn}"
  container_definitions    = "${data.template_file.loyalty.rendered}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 2048
}

resource "aws_ecs_task_definition" "map-service" {
  family                   = "${var.environment}_map-service"
  task_role_arn            = "${var.ecs_role_arn}"
  execution_role_arn       = "${var.ecs_role_arn}"
  container_definitions    = "${data.template_file.map-service.rendered}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 2048
}

resource "aws_ecs_task_definition" "outlet-service" {
  family                   = "${var.environment}_outlet_service"
  task_role_arn            = "${var.ecs_role_arn}"
  execution_role_arn       = "${var.ecs_role_arn}"
  container_definitions    = "${data.template_file.outlet-service.rendered}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 2048
}

resource "aws_ecs_task_definition" "notification-producer" {
  family                   = "${var.environment}_producer"
  task_role_arn            = "${var.ecs_role_arn}"
  execution_role_arn       = "${var.ecs_role_arn}"
  container_definitions    = "${data.template_file.notification-producer.rendered}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_task_definition" "retailer-module" {
  family                   = "${var.environment}_retailer_module"
  task_role_arn            = "${var.ecs_role_arn}"
  execution_role_arn       = "${var.ecs_role_arn}"
  container_definitions    = "${data.template_file.retailer-module.rendered}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_task_definition" "sshd" {
  family                   = "${var.environment}_sshd"
  task_role_arn            = "${var.ecs_role_arn}"
  execution_role_arn       = "${var.ecs_role_arn}"
  container_definitions    = "${data.template_file.sshd.rendered}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_task_definition" "feedback-module" {
  family                   = "${var.environment}_feedback-module"
  task_role_arn            = "${var.ecs_role_arn}"
  execution_role_arn       = "${var.ecs_role_arn}"
  container_definitions    = "${data.template_file.feedback-module.rendered}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
}
