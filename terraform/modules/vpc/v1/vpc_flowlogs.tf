###################### Enable VPC Flow Logs #################################
resource "aws_flow_log" "vpc_flowlogs" {
  count                = var.vpc_flowlogs ? 1 : 0
  log_destination      = "${var.environment}-objects"
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.vpc.id
}
