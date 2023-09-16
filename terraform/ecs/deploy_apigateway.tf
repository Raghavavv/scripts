data "template_file" "deploy_apigateway" {
  template = "${file("templates/deploy_apigateway.sh")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
    branch      = "${var.git_target_branch}"
  }
}

data "template_file" "bitbucket_pipelines_apigateway" {
  template = "${file("templates/pipelines_apigateway.yml")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
    branch      = "${var.git_target_branch}"
  }
}

data "template_file" "fetch_code_apigateway" {
  template = "${file("templates/fetch_code_apigateway.sh")}"
  vars   = {
    branch      = "${var.git_target_branch}"
    username = "${var.bitbucket_credentials["username"]}"
    password = "${var.bitbucket_credentials["password"]}"
  }
}

resource "null_resource" "git_repo_clone_apigateway" {
  provisioner "local-exec" {
    command = "${data.template_file.fetch_code_apigateway.rendered}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["aws_lb.elb"]
}

resource "null_resource" "git_ops_apigateway" {
  provisioner "local-exec" {
    command = "cd apigateway && /usr/bin/git checkout -b ${var.git_target_branch} ${var.git_source_branch}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.git_repo_clone_apigateway"]
}

resource "null_resource" "copy_deploy_file_apigateway" {
  provisioner "local-exec" {
    command = "cat > apigateway/ops/deploy.sh <<EOF\n${data.template_file.deploy_apigateway.rendered}\nEOF"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.git_ops_apigateway"]
}

resource "null_resource" "copy_pipelines_file_apigateway" {
  provisioner "local-exec" {
    command = "cat > apigateway/bitbucket-pipelines.yml <<EOF\n${data.template_file.bitbucket_pipelines_apigateway.rendered}\nEOF"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.git_ops_apigateway"]
}

resource "null_resource" "git_change_operations_apigateway" {
  provisioner "local-exec" {
    command = "cd apigateway && /usr/bin/git config --global user.name \"${var.git_config_user}\" && /usr/bin/git config --global user.email \"${var.git_config_email}\" && /usr/bin/git add . && /usr/bin/git commit -m \"deploying apigateway\" && /usr/bin/git push -f --repo https://${var.bitbucket_credentials["username"]}:${var.bitbucket_credentials["password"]}@bitbucket.org/bizom/apigateway.git -u origin ${var.git_target_branch}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.copy_deploy_file_apigateway"]
  #depends_on = ["null_resource.copy_deploy_file_apigateway,null_resource.copy_pipelines_file_apigateway"]
}

resource "null_resource" "cleanup_apigateway" {
  provisioner "local-exec" {
    command = "rm -rf /tmp/apigateway && mv apigateway /tmp"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.git_change_operations_apigateway"]
}
