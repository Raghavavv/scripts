/*
resource "kubernetes_namespace" "mainnamespace" {
  metadata {
    annotations = {
      name = "${var.environment}-services"
    }

    labels = {
      mylabel = "defualt_namespace"
    }

    name = "${var.environment}-services"
  }
} */
