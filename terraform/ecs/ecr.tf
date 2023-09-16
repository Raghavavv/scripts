resource "aws_ecr_repository" "ecr_repo_name" {
  count                = "${length(var.services)}"
  name                 = "${element(var.services,count.index)}"
  image_tag_mutability = "MUTABLE"
}
