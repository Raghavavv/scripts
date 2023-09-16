# Security Group for ELB
resource "aws_security_group" "elb_sg" {
  name        = "${var.elb_sg[var.environment]}"
  description = "Security group for ${var.environment} ELB"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# External Load Balancer creation
resource "aws_lb" "elb" {
  name                       = "${var.elb_name[var.environment]}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = ["${aws_security_group.elb_sg.id}"]
  #subnets                    = ["aws_subnet.public[*].id"]
  subnets                    = ["${aws_subnet.public.*.id}"]
  enable_deletion_protection = false
  tags = {
    Environment = "${var.environment}"
  }
}

# Target groups creation
resource "aws_lb_target_group" "access-service" {
  name        = "ecs-${var.environment}-access"
  port        = 9090
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  health_check {    
    healthy_threshold   = 2    
    unhealthy_threshold = 5    
    timeout             = 20   
    interval            = 30    
    path                = "/actuator"    
  }
}

resource "aws_lb_target_group" "apigateway" {
  name        = "ecs-${var.environment}-apigateway"
  port        = 8081
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
}

resource "aws_lb_target_group" "config" {
  name        = "ecs-${var.environment}-config"
  port        = 8102
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  health_check {    
    healthy_threshold   = 2    
    unhealthy_threshold = 5    
    timeout             = 20   
    interval            = 30    
    path                = "/actuator"    
  }
}

resource "aws_lb_target_group" "ell" {
  name        = "ecs-${var.environment}-ell"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  health_check {    
    healthy_threshold   = 2    
    unhealthy_threshold = 5    
    timeout             = 20   
    interval            = 30    
    path                = "/actuator"    
  }
}

resource "aws_lb_target_group" "loyalty" {
  name        = "ecs-${var.environment}-loyalty"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  health_check {    
    healthy_threshold   = 2    
    unhealthy_threshold = 5    
    timeout             = 20   
    interval            = 30    
    path                = "/actuator"    
  }
}

resource "aws_lb_target_group" "map-service" {
  name        = "ecs-${var.environment}-map-service"
  port        = 8090
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  health_check {    
    healthy_threshold   = 2    
    unhealthy_threshold = 5    
    timeout             = 20   
    interval            = 30    
    path                = "/actuator"    
  }
}

resource "aws_lb_target_group" "outlet-service" {
  name        = "ecs-${var.environment}-outlet-service"
  port        = 9093
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  health_check {    
    healthy_threshold   = 2    
    unhealthy_threshold = 5    
    timeout             = 20   
    interval            = 30    
    path                = "/actuator"    
  }
}

resource "aws_lb_target_group" "notification-consumer" {
  name        = "ecs-${var.environment}-consumer"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  health_check {    
    healthy_threshold   = 2    
    unhealthy_threshold = 5    
    timeout             = 20   
    interval            = 30    
    path                = "/actuator"    
  }
}

resource "aws_lb_target_group" "notification-producer" {
  name        = "ecs-${var.environment}-producer"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  health_check {    
    healthy_threshold   = 2    
    unhealthy_threshold = 5    
    timeout             = 20   
    interval            = 30    
    path                = "/actuator"    
  }
}

resource "aws_lb_target_group" "retailer-module" {
  name        = "ecs-${var.environment}-retailer-module"
  port        = 9092
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  health_check {    
    healthy_threshold   = 2    
    unhealthy_threshold = 5    
    timeout             = 20   
    interval            = 30    
    path                = "/actuator"    
  }
}

resource "aws_lb_target_group" "feedback-module" {
  name        = "ecs-${var.environment}-feedback-module"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.bizom_vpc.id}"
  health_check {    
    healthy_threshold   = 2    
    unhealthy_threshold = 5    
    timeout             = 20   
    interval            = 30    
    path                = "/actuator"    
  }
}

# Creating load balancer listeners
resource "aws_lb_listener" "http" {
  load_balancer_arn = "${aws_lb.elb.arn}"
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_302"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = "${aws_lb.elb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${var.certificate_arn[var.aws_region]}"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.apigateway.arn}"
  }
}

resource "aws_lb_listener_rule" "host_based_routing_access" {
  listener_arn = "${aws_lb_listener.http.arn}"
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.access-service.arn}"
  }
  condition {
    field  = "host-header"
    values = ["access-service.${var.environment}"]
  }
}

resource "aws_lb_listener_rule" "host_based_routing_config" {
  listener_arn = "${aws_lb_listener.http.arn}"
  priority     = 200
  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.config.arn}"
  }
  condition {
    field  = "host-header"
    values = ["config.${var.environment}"]
  }
}

resource "aws_lb_listener_rule" "host_based_routing_ell" {
  listener_arn = "${aws_lb_listener.http.arn}"
  priority     = 300
  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.ell.arn}"
  }
  condition {
    field  = "host-header"
    values = ["ell.${var.environment}"]
  }
}

resource "aws_lb_listener_rule" "host_based_routing_loyalty" {
  listener_arn = "${aws_lb_listener.http.arn}"
  priority     = 400
  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.loyalty.arn}"
  }
  condition {
    field  = "host-header"
    values = ["loyalty.${var.environment}"]
  }
}

resource "aws_lb_listener_rule" "host_based_routing_map-service" {
  listener_arn = "${aws_lb_listener.http.arn}"
  priority     = 500
  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.map-service.arn}"
  }
  condition {
    field  = "host-header"
    values = ["map-service.${var.environment}"]
  }
}

resource "aws_lb_listener_rule" "host_based_routing_outlet_service" {
  listener_arn = "${aws_lb_listener.http.arn}"
  priority     = 600
  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.outlet-service.arn}"
  }
  condition {
    field  = "host-header"
    values = ["outlet-service.${var.environment}"]
  }
}

resource "aws_lb_listener_rule" "host_based_routing_notification_consumer" {
  listener_arn = "${aws_lb_listener.http.arn}"
  priority     = 700
  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.notification-consumer.arn}"
  }
  condition {
    field  = "host-header"
    values = ["notification-consumer.${var.environment}"]
  }
}

resource "aws_lb_listener_rule" "host_based_routing_produer" {
  listener_arn = "${aws_lb_listener.http.arn}"
  priority     = 710
  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.notification-producer.arn}"
  }
  condition {
    field  = "host-header"
    values = ["notitication-producer.${var.environment}"]
  }
}

resource "aws_lb_listener_rule" "host_based_routing_retailer_module" {
  listener_arn = "${aws_lb_listener.http.arn}"
  priority     = 720
  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.retailer-module.arn}"
  }
  condition {
    field  = "host-header"
    values = ["retailer-module.${var.environment}"]
  }
}

resource "aws_lb_listener_rule" "host_based_routing_feedback-module" {
  listener_arn = "${aws_lb_listener.http.arn}"
  priority     = 730
  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.feedback-module.arn}"
  }
  condition {
    field  = "host-header"
    values = ["feedback-module.${var.environment}"]
  }
}

output "elb_endpoint" { value = "${aws_lb.elb.dns_name}" }
