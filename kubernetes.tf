provider "kubernetes" {
  host                   = aws_eks_cluster.hanalink_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.hanalink_cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.hanalink_cluster.name]
  }
}

data "aws_eks_cluster_auth" "hanalink_cluster" {
  name = aws_eks_cluster.hanalink_cluster.name
}

resource "kubernetes_deployment" "hanalink_spring_boot_app" {
  metadata {
    name = "hanalink-spring-boot-app"
    labels = {
      app = "hanalink-spring-boot-app"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "hanalink-spring-boot-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "hanalink-spring-boot-app"
        }
      }
      spec {
        container {
          name  = "hanalink-spring-boot-app"
          image = "tlsaudwl/hanalink-spring-boot:latest"
          port {
            container_port = 8080
          }
          env {
            name  = "SPRING_DATASOURCE_URL"
            value = "jdbc:mysql://hanalink-db.cbmoo6w6k67n.ap-northeast-2.rds.amazonaws.com/hanalink"
          }
          env {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = "root"
          }
          env {
            name  = "SPRING_DATASOURCE_PASSWORD"
            value = "hanalink123"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "hanalink_spring_boot_service" {
  metadata {
    name = "hanalink-spring-boot-service"
  }
  spec {
    selector = {
      app = "hanalink-spring-boot-app"
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "hanalink_react_app" {
  metadata {
    name = "hanalink-react-app"
    labels = {
      app = "hanalink-react-app"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "hanalink-react-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "hanalink-react-app"
        }
      }
      spec {
        container {
          name  = "hanalink-react-app"
          image = "tlsaudwl/hanalink-react:latest"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "hanalink_react_service" {
  metadata {
    name = "hanalink-react-service"
  }
  spec {
    selector = {
      app = "hanalink-react-app"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
