data "template_file" "deploy_config" {
  template = "${file("templates/deploy_config.sh")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
    branch      = "${var.git_target_branch}"
  }
}

data "template_file" "bitbucket_pipelines_config" {
  template = "${file("templates/pipelines.yml")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
    branch      = "${var.git_target_branch}"
  }
}

data "template_file" "fetch_code_config" {
  template = "${file("templates/fetch_code_config.sh")}"
  vars   = {
    branch      = "${var.git_target_branch}"
    username = "${var.bitbucket_credentials["username"]}"
    password = "${var.bitbucket_credentials["password"]}"
  }
}

resource "null_resource" "git_repo_clone_config" {
  provisioner "local-exec" {
    command = "${data.template_file.fetch_code_config.rendered}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["aws_lb.elb"]
}

resource "null_resource" "git_ops_config" {
  provisioner "local-exec" {
    command = "cd bizom-config-server && /usr/bin/git checkout -b ${var.git_target_branch} ${var.git_source_branch}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.git_repo_clone_config"]
}

resource "null_resource" "copy_deploy_file_config" {
  provisioner "local-exec" {
    command = "cat > bizom-config-server/ops/deploy.sh <<EOF\n${data.template_file.deploy_config.rendered}\nEOF"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.git_ops_config"]
}

resource "null_resource" "copy_pipelines_file_config" {
  provisioner "local-exec" {
    command = "cat > bizom-config-server/bitbucket-pipelines.yml <<EOF\n${data.template_file.bitbucket_pipelines_config.rendered}\nEOF"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.git_ops_config"]
}

resource "null_resource" "git_change_operations_config" {
  provisioner "local-exec" {
    command = "cd bizom-config-server && /usr/bin/git config --global user.name \"${var.git_config_user}\" && /usr/bin/git config --global user.email \"${var.git_config_email}\" && /usr/bin/git add . && /usr/bin/git commit -m \"deploying config-server\" && /usr/bin/git push -f --repo https://${var.bitbucket_credentials["username"]}:${var.bitbucket_credentials["password"]}@bitbucket.org/bizom/bizom-config-server.git -u origin ${var.git_target_branch}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.copy_deploy_file_config"]
  #depends_on = ["null_resource.copy_deploy_file_config,null_resource.copy_pipelines_file_config"]
}

resource "null_resource" "cleanup_config" {
  provisioner "local-exec" {
    command = "rm -rf /tmp/bizom-config-server && mv bizom-config-server /tmp"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.git_change_operations_config"]
}
