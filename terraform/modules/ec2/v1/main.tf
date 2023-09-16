resource "aws_instance" "main" {
  count                       = var.number_of_instances
  ami                         = var.ami_id
  instance_type               = var.instance_type
  monitoring                  = var.monitoring
  availability_zone           = element(var.azs, count.index)
  associate_public_ip_address = var.associate_public_ip_address
  ebs_optimized               = var.ebs_optimized
  key_name                    = "${var.server_name}-keypair"
  iam_instance_profile	      = aws_iam_instance_profile.ec2-instance-profile.name

  vpc_security_group_ids = [aws_security_group.control_traffic.id]

  user_data = "${file("/home/raghavav/scripts/terraform/modules/ec2/v1/userdata.sh")}"
  depends_on = [
    aws_security_group.control_traffic,
    aws_iam_role_policy_attachment.MobithonS3_bizomlivelogs_putobject,
    aws_iam_role_policy_attachment.MobithonCloudwatch_alarm_management,
    aws_iam_role_policy_attachment.MobithonCloudWatchAgentServerPolicy

  ]
  
  tags = {
    "Name" = "${var.environment}-${var.server_name}"
    "CostCentre"  = var.costcentre
  }
}

