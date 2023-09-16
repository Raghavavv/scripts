data "template_file" "deploy" {
  template = "${file("templates/deploy_ell.sh")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
    branch      = "${var.git_target_branch}"
  }
}

data "template_file" "bitbucket_pipelines" {
  template = "${file("templates/pipelines.yml")}"
  vars   = {
    environment = "${var.environment}"
    region      = "${var.aws_region}"
    branch      = "${var.git_target_branch}"
  }
}

data "template_file" "fetch_code" {
  template = "${file("templates/fetch_code_ell.sh")}"
  vars   = {
    branch      = "${var.git_target_branch}"
    username = "${var.bitbucket_credentials["username"]}"
    password = "${var.bitbucket_credentials["password"]}"
  }
}

data "local_file" "edit_deploy" {
  filename = "files/edit_deploy.sh"
}

resource "null_resource" "git_repo_clone" {
  provisioner "local-exec" {
    command = "${data.template_file.fetch_code.rendered}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["aws_lb.elb"]
}

resource "null_resource" "git_ops" {
  provisioner "local-exec" {
    command = "cd bizom && /usr/bin/git checkout -b ${var.git_target_branch} ${var.git_source_branch}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.git_repo_clone"]
}

resource "null_resource" "copy_deploy_file" {
  provisioner "local-exec" {
    command = "cat > bizom/ops/deploy.sh <<EOF\n${data.template_file.deploy.rendered}\nEOF"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.git_ops"]
}

resource "null_resource" "edit_deploy_file" {
  provisioner "local-exec" {
    command = "files/edit_deploy.sh"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.copy_deploy_file"]
}

resource "null_resource" "copy_pipelines_file" {
  provisioner "local-exec" {
    command = "cat > bizom/bitbucket-pipelines.yml <<EOF\n${data.template_file.bitbucket_pipelines.rendered}\nEOF"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.git_ops"]
}

resource "null_resource" "git_change_operations" {
  provisioner "local-exec" {
    command = "cd bizom && /usr/bin/git config --global user.name \"${var.git_config_user}\" && /usr/bin/git config --global user.email \"${var.git_config_email}\" && /usr/bin/git add . && git commit -m \"deploying all the serverices\" && /usr/bin/git push -f --repo https://${var.bitbucket_credentials["username"]}:${var.bitbucket_credentials["password"]}@bitbucket.org/bizom/bizom.git -u origin ${var.git_target_branch}"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.copy_deploy_file"]
  #depends_on = ["null_resource.copy_deploy_file,null_resource.copy_pipelines_file"]
}

resource "null_resource" "cleanup" {
  provisioner "local-exec" {
    command = "rm -rf /tmp/bizom && mv bizom /tmp"
    interpreter = ["/bin/bash", "-c"]
  }
  depends_on = ["null_resource.git_change_operations"]
}
