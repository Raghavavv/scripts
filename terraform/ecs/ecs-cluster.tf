resource "aws_ecs_cluster" "ecs-cluster" {
  name = "${var.environment}"
}

resource "aws_service_discovery_private_dns_namespace" "terraform" {
#  name        = "terraform.${var.environment}"
  name        = "${var.environment}"
  description = "terraform"
  vpc         = "${aws_vpc.bizom_vpc.id}"
}

# Security Group for config-server
resource "aws_security_group" "config_sg" {
  name        = "config_${var.environment}_sg"
  description = "Security group for ${var.environment} config"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8102
    to_port     = 8102
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr[var.environment]}"]
  }
}

# Security Group for access-service
resource "aws_security_group" "access-service_sg" {
  name        = "access-service_${var.environment}_sg"
  description = "Security group for ${var.environment} access-service"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr[var.environment]}"]
  }
}

# Security Group for ell
resource "aws_security_group" "ell_sg" {
  name        = "ell_${var.environment}_sg"
  description = "Security group for ${var.environment} ell"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr[var.environment]}"]
  }
}

# Security Group for loyalty
resource "aws_security_group" "loyalty_sg" {
  name        = "loyalty_${var.environment}_sg"
  description = "Security group for ${var.environment} loyalty"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr[var.environment]}"]
  }
}

# Security Group for map-service
resource "aws_security_group" "map-service_sg" {
  name        = "map-service_${var.environment}_sg"
  description = "Security group for ${var.environment} map-service"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8090
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr[var.environment]}"]
  }
}

# Security Group for notification-consumer
resource "aws_security_group" "notification-consumer_sg" {
  name        = "notification-consumer_${var.environment}_sg"
  description = "Security group for ${var.environment} notification-consumer"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr[var.environment]}"]
  }
}

# Security Group for notification-producer
resource "aws_security_group" "notification-producer_sg" {
  name        = "notification-producer_${var.environment}_sg"
  description = "Security group for ${var.environment} notification-producer"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr[var.environment]}"]
  }
}

# Security Group for retailer_module
resource "aws_security_group" "retailer-module_sg" {
  name        = "retailer-module_${var.environment}_sg"
  description = "Security group for ${var.environment} retailer-module"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr[var.environment]}"]
  }
}

# Security Group for generic-outlet-service
resource "aws_security_group" "outlet-service_sg" {
  name        = "outlet-service_${var.environment}_sg"
  description = "Security group for ${var.environment} outlet-service"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr[var.environment]}"]
  }
}

# Security Group for apigateway
resource "aws_security_group" "apigateway_sg" {
  name        = "apigateway_${var.environment}_sg"
  description = "Security group for ${var.environment} apigateway"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr[var.environment]}"]
  }
}

# Security Group for sshd
resource "aws_security_group" "sshd_sg" {
  name        = "sshd_${var.environment}_sg"
  description = "Security group for ${var.environment} apigateway"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for feedback-module
resource "aws_security_group" "feedback-module_sg" {
  name        = "feedback-module_${var.environment}_sg"
  description = "Security group for ${var.environment} feedback-module"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr[var.environment]}"]
  }
}


resource "aws_service_discovery_service" "config" {
  name = "config"
  description = "config service discovery"
  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.terraform.id}"
    dns_records {
      ttl  = 100
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "access-service" {
  name = "access-service"
  description = "access-service service discovery"
  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.terraform.id}"
    dns_records {
      ttl  = 100
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "ell" {
  name = "ell"
  description = "ell service discovery"
  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.terraform.id}"
    dns_records {
      ttl  = 100
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "loyalty" {
  name = "loyalty"
  description = "loyalty service discovery"
  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.terraform.id}"
    dns_records {
      ttl  = 100
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "map-service" {
  name = "map-service"
  description = "map-service service discovery"
  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.terraform.id}"
    dns_records {
      ttl  = 100
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "outlet-service" {
  name = "outlet-service"
  description = "outlet-service service discovery"
  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.terraform.id}"
    dns_records {
      ttl  = 100
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "notification-consumer" {
  name = "notification-consumer"
  description = "notification-consumer service discovery"
  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.terraform.id}"
    dns_records {
      ttl  = 100
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "notification-producer" {
  name = "notification-producer"
  description = "notification-producer service discovery"
  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.terraform.id}"
    dns_records {
      ttl  = 100
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "retailer-module" {
  name = "retailer-module"
  description = "retailer-module service discovery"
  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.terraform.id}"
    dns_records {
      ttl  = 100
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "apigateway" {
  name = "apigateway"
  description = "apigateway service discovery"
  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.terraform.id}"
    dns_records {
      ttl  = 100
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "feedback-module" {
  name = "feedback-module"
  description = "feedback-module service discovery"
  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.terraform.id}"
    dns_records {
      ttl  = 100
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_service" "config" {
  name            = "config"
  cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.config.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 600
  load_balancer {
    target_group_arn = "${aws_lb_target_group.config.arn}"
    container_name   = "config-server"
    container_port   = 8102
  }
  network_configuration {
    subnets          = ["${aws_subnet.public.*.id}"]
    security_groups  = ["${aws_security_group.config_sg.id}"]
    assign_public_ip = "true"
  }
  service_registries {
    registry_arn   = "${aws_service_discovery_service.config.arn}"
  }
}

resource "aws_ecs_service" "access-service" {
  name            = "access-service"
  cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.access-service.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 600
  load_balancer {
    target_group_arn = "${aws_lb_target_group.access-service.arn}"
    container_name   = "access-service"
    container_port   = 9090
  }
  network_configuration {
    subnets          = ["${aws_subnet.public.*.id}"]
    security_groups  = ["${aws_security_group.access-service_sg.id}"]
    assign_public_ip = "true"
  }
  service_registries {
    registry_arn   = "${aws_service_discovery_service.access-service.arn}"
  }
  depends_on = ["aws_ecs_service.config"]
}

resource "aws_ecs_service" "ell" {
  name            = "ell"
  cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.ell.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 600
  load_balancer {
    target_group_arn = "${aws_lb_target_group.ell.arn}"
    container_name   = "ell"
    container_port   = 8080
  }
  network_configuration {
    subnets          = ["${aws_subnet.public.*.id}"]
    security_groups  = ["${aws_security_group.ell_sg.id}"]
    assign_public_ip = "true"
  }
  service_registries {
    registry_arn   = "${aws_service_discovery_service.ell.arn}"
  }
  depends_on = ["aws_ecs_service.config"]
}

resource "aws_ecs_service" "loyalty" {
  name            = "loyalty"
  cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.loyalty.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 600
  load_balancer {
    target_group_arn = "${aws_lb_target_group.loyalty.arn}"
    container_name   = "loyalty"
    container_port   = 8080
  }
  network_configuration {
    subnets          = ["${aws_subnet.public.*.id}"]
    security_groups  = ["${aws_security_group.loyalty_sg.id}"]
    assign_public_ip = "true"
  }
  service_registries {
    registry_arn   = "${aws_service_discovery_service.loyalty.arn}"
  }
  depends_on = ["aws_ecs_service.config"]
}

resource "aws_ecs_service" "map-service" {
  name            = "map-service"
  cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.map-service.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 600
  load_balancer {
    target_group_arn = "${aws_lb_target_group.map-service.arn}"
    container_name   = "map-service"
    container_port   = 8090
  }
  network_configuration {
    subnets          = ["${aws_subnet.public.*.id}"]
    security_groups  = ["${aws_security_group.map-service_sg.id}"]
    assign_public_ip = "true"
  }
  service_registries {
    registry_arn   = "${aws_service_discovery_service.map-service.arn}"
  }
  depends_on = ["aws_ecs_service.config"]
}

resource "aws_ecs_service" "outlet-service" {
  name            = "outlet-service"
  cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.outlet-service.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 600
  load_balancer {
    target_group_arn = "${aws_lb_target_group.outlet-service.arn}"
    container_name   = "outlet-service"
    container_port   = 9093
  }
  network_configuration {
    subnets          = ["${aws_subnet.public.*.id}"]
    security_groups  = ["${aws_security_group.outlet-service_sg.id}"]
    assign_public_ip = "true"
  }
  service_registries {
    registry_arn   = "${aws_service_discovery_service.outlet-service.arn}"
  }
  depends_on = ["aws_ecs_service.config"]
}

resource "aws_ecs_service" "notification-consumer" {
  name            = "notification-consumer"
  cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.notification-consumer.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 600
  load_balancer {
    target_group_arn = "${aws_lb_target_group.notification-consumer.arn}"
    container_name   = "notification-consumer"
    container_port   = 8080
  }
  network_configuration {
    subnets          = ["${aws_subnet.public.*.id}"]
    security_groups  = ["${aws_security_group.notification-consumer_sg.id}"]
    assign_public_ip = "true"
  }
  service_registries {
    registry_arn   = "${aws_service_discovery_service.notification-consumer.arn}"
  }
  depends_on = ["aws_ecs_service.config"]
}

resource "aws_ecs_service" "notification-producer" {
  name            = "notification-producer"
  cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.notification-producer.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 600
  load_balancer {
    target_group_arn = "${aws_lb_target_group.notification-producer.arn}"
    container_name   = "notification-producer"
    container_port   = 8080
  }
  network_configuration {
    subnets          = ["${aws_subnet.public.*.id}"]
    security_groups  = ["${aws_security_group.notification-producer_sg.id}"]
    assign_public_ip = "true"
  }
  service_registries {
    registry_arn   = "${aws_service_discovery_service.notification-producer.arn}"
  }
  depends_on = ["aws_ecs_service.config"]
}

resource "aws_ecs_service" "retailer-module" {
  name            = "retailer-module"
  cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.retailer-module.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 600
  load_balancer {
    target_group_arn = "${aws_lb_target_group.retailer-module.arn}"
    container_name   = "retailer-module"
    container_port   = 9092
  }
  network_configuration {
    subnets          = ["${aws_subnet.public.*.id}"]
    security_groups  = ["${aws_security_group.retailer-module_sg.id}"]
    assign_public_ip = "true"
  }
  service_registries {
    registry_arn   = "${aws_service_discovery_service.retailer-module.arn}"
  }
  depends_on = ["aws_ecs_service.config"]
}

resource "aws_ecs_service" "apigateway" {
  name            = "apigateway"
  cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.apigateway.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 600
  load_balancer {
    target_group_arn = "${aws_lb_target_group.apigateway.arn}"
    container_name   = "apigateway"
    container_port   = 8081
  }
  network_configuration {
    subnets          = ["${aws_subnet.public.*.id}"]
    security_groups  = ["${aws_security_group.apigateway_sg.id}"]
    assign_public_ip = "true"
  }
  service_registries {
    registry_arn   = "${aws_service_discovery_service.apigateway.arn}"
  }
#  depends_on = ["aws_ecs_service.ell,aws_ecs_service.access-service"]
  depends_on = ["aws_ecs_service.ell"]
}

resource "aws_ecs_service" "feedback-module" {
  name            = "feedback-module"
  cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.feedback-module.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 600
  load_balancer {
    target_group_arn = "${aws_lb_target_group.feedback-module.arn}"
    container_name   = "feedback-module"
    container_port   = 8080
  }
  network_configuration {
    subnets          = ["${aws_subnet.public.*.id}"]
    security_groups  = ["${aws_security_group.feedback-module_sg.id}"]
    assign_public_ip = "true"
  }
  service_registries {
    registry_arn   = "${aws_service_discovery_service.feedback-module.arn}"
  }
  depends_on = ["aws_ecs_service.config"]
}

resource "aws_ecs_service" "sshd" {
  name            = "sshd"
  cluster         = "${aws_ecs_cluster.ecs-cluster.id}"
  task_definition = "${aws_ecs_task_definition.sshd.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = ["${aws_subnet.public.*.id}"]
    security_groups  = ["${aws_security_group.sshd_sg.id}"]
    assign_public_ip = "true"
  }
}

output "private_dns_namespace" { value = "aws_service_discovery_private_dns_namespace.terraform.name" }
