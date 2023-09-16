data "template_file" "deploy_outlet" {
  template = "${file("templates/deploy_outlet.sh")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
    branch      = "${var.git_target_branch}"
  }
}

data "template_file" "bitbucket_pipelines_outlet" {
  template = "${file("templates/pipelines_outlet.yml")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
    branch      = "${var.git_target_branch}"
  }
}

data "template_file" "fetch_code_outlet" {
  template = "${file("templates/fetch_code_outlet.sh")}"
  vars   = {
    branch   = "${var.git_target_branch}"
    username = "${var.bitbucket_credentials["username"]}"
    password = "${var.bitbucket_credentials["password"]}"
  }
}

resource "null_resource" "git_repo_clone_outlet" {
  provisioner "local-exec" {
    command = "${data.template_file.fetch_code_outlet.rendered}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["aws_lb.elb"]
}

resource "null_resource" "git_ops_outlet" {
  provisioner "local-exec" {
    command = "cd generic-outlet-service && /usr/bin/git checkout -b ${var.git_target_branch} ${var.git_source_branch}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.git_repo_clone_outlet"]
}

resource "null_resource" "copy_deploy_file_outlet" {
  provisioner "local-exec" {
    command = "cat > generic-outlet-service/ops/deploy.sh <<EOF\n${data.template_file.deploy_outlet.rendered}\nEOF"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.git_ops_outlet"]
}

resource "null_resource" "copy_pipelines_file_outlet" {
  provisioner "local-exec" {
    command = "cat > generic-outlet-service/bitbucket-pipelines.yml <<EOF\n${data.template_file.bitbucket_pipelines_outlet.rendered}\nEOF"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.git_ops_outlet"]
}

resource "null_resource" "git_change_operations_outlet" {
  provisioner "local-exec" {
    command = "cd generic-outlet-service && /usr/bin/git config --global user.name \"${var.git_config_user}\" && /usr/bin/git config --global user.email \"${var.git_config_email}\" && /usr/bin/git add . && git commit -m \"deploying generic-outlet-service\" && /usr/bin/git push -f --repo https://${var.bitbucket_credentials["username"]}:${var.bitbucket_credentials["password"]}@bitbucket.org/bizom/generic-outlet-service.git -u origin ${var.git_target_branch}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.copy_deploy_file_outlet"]
  #depends_on = ["null_resource.copy_deploy_file,null_resource.copy_pipelines_file"]
}

resource "null_resource" "cleanup_outlet" {
  provisioner "local-exec" {
    command = "rm -rf /tmp/generic-outlet-service && mv generic-outlet-service /tmp"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.git_change_operations_outlet"]
}
