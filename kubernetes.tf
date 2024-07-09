provider "kubernetes" {
  host = aws_eks_cluster.new_hanalink_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.new_hanalink_cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command = "aws"
    args = ["eks", "get-token", "--cluster-name", aws_eks_cluster.new_hanalink_cluster.name, "--region", "ap-northeast-2"]
  }
}

data "aws_eks_cluster_auth" "new_hanalink_cluster" {
  name = aws_eks_cluster.new_hanalink_cluster.name
}

resource "kubernetes_deployment" "new_hanalink_spring_boot_app" {
  metadata {
    name = "new-hanalink-spring-boot-app"
    labels = {
      app = "new-hanalink-spring-boot-app"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "new-hanalink-spring-boot-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "new-hanalink-spring-boot-app"
        }
      }
      spec {
        container {
          name = "new-hanalink-spring-boot-app"
          image = "tlsaudwl/hanalink-spring-boot:latest"
          port {
            container_port = 8080
          }
          env {
            name = "SPRING_DATASOURCE_URL"
            value = "jdbc:mysql://hanalink-db.cbmoo6w6k67n.ap-northeast-2.rds.amazonaws.com/hanalink"
          }
          env {
            name = "SPRING_DATASOURCE_USERNAME"
            value = "root"
          }
          env {
            name = "SPRING_DATASOURCE_PASSWORD"
            value = "hanalink123"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "new_hanalink_spring_boot_service" {
  metadata {
    name = "new-hanalink-spring-boot-service"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" : "alb"
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" : "HTTP"
      "service.beta.kubernetes.io/aws-load-balancer-ssl-ports" : "443"
      "service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout" : "60"
    }
  }
  spec {
    selector = {
      app = "new-hanalink-spring-boot-app"
    }
    port {
      port = 8080
      target_port = 8080
    }
    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "new_hanalink_react_app" {
  metadata {
    name = "new-hanalink-react-app"
    labels = {
      app = "new-hanalink-react-app"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "new-hanalink-react-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "new-hanalink-react-app"
        }
      }
      spec {
        container {
          name = "new-hanalink-react-app"
          image = "tlsaudwl/hanalink-react:latest"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "new_hanalink_react_service" {
  metadata {
    name = "new-hanalink-react-service"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" : "alb"
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" : "HTTP"
      "service.beta.kubernetes.io/aws-load-balancer-ssl-ports" : "443"
      "service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout" : "60"
    }
  }
  spec {
    selector = {
      app = "new-hanalink-react-app"
    }
    port {
      port = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
