resource "aws_iam_role" "MobithonCloudWatchAgentServerRole" {
  name                  = "MobithonCloudWatchAgentServerRole"
  force_detach_policies = true

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}


resource "aws_iam_policy" "MobithonCloudWatchAgentServerPolicy" {
  name   = "MobithonCloudWatchAgentServerPolicy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "ec2:DescribeVolumes",
                "ec2:DescribeTags",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "logs:CreateLogStream",
                "logs:CreateLogGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "MobithonCloudWatchAgentServerPolicy" {
  policy_arn = aws_iam_policy.MobithonCloudWatchAgentServerPolicy.arn
  role       = aws_iam_role.MobithonCloudWatchAgentServerRole.name
}

resource "aws_iam_policy" "MobithonS3_bizomlivelogs_putobject" {
  name   = "MobithonS3_bizomlivelogs_putobject"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::bizomlivelogs/*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "MobithonS3_bizomlivelogs_putobject" {
  policy_arn = aws_iam_policy.MobithonS3_bizomlivelogs_putobject.arn
  role       = aws_iam_role.MobithonCloudWatchAgentServerRole.name
}

resource "aws_iam_policy" "MobithonCloudwatch_alarm_management" {
  name   = "MobithonCloudwatch_alarm_management"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricAlarm",
                "cloudwatch:PutMetricData",
                "cloudwatch:DescribeAlarmHistory",
                "cloudwatch:EnableAlarmActions",
                "cloudwatch:DeleteAlarms",
                "cloudwatch:DisableAlarmActions",
                "cloudwatch:DescribeAlarmsForMetric",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:SetAlarmState"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "MobithonCloudwatch_alarm_management" {
  policy_arn = aws_iam_policy.MobithonCloudwatch_alarm_management.arn
  role       = aws_iam_role.MobithonCloudWatchAgentServerRole.name
}

