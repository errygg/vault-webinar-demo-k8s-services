data "terraform_remote_state" "k8s_cluster" {
  backend = "atlas"
  config {
    name = "lanceplarsenv2/vault-webinar-demo-k8s-cluster"
  }
}

provider "kubernetes" {
  host = "${terraform_remote_state.k8s_cluster.k8s_endpoint}"
  client_certificate = "${base64decode(terraform_remote_state.k8s_cluster.k8s_master_auth_client_certificate)}"
  client_key = "${base64decode(terraform_remote_state.k8s_cluster.k8s_master_auth_client_key)}"
  cluster_ca_certificate = "${base64decode(terraform_remote_state.k8s_cluster.k8s_master_auth_cluster_ca_certificate)}"
}

resource "kubernetes_service_account" "spring" {
  metadata {
    name = "spring"
  }
}

resource "kubernetes_pod" "spring-backend" {
  metadata {
    name = "spring-backend"
    labels {
      App = "spring-backend"
    }
  }
  spec {
    service_account_name = "${kubernetes_service_account.spring.metadata.0.name}"
    container {
      image = "lanceplarsen/spring-vault-demo"
      image_pull_policy = "Always"
      name  = "spring-backend"
      port {
        container_port = 8080
      }
    }
  }
}

resource "kubernetes_service" "spring-backend" {
  metadata {
    name = "spring-backend"
  }
  spec {
    selector {
      App = "${kubernetes_pod.spring-backend.metadata.0.labels.App}"
    }
    port {
      port = 8080
      target_port = 8080
    }
  }
}

resource "kubernetes_pod" "spring-frontend" {
  metadata {
    name = "spring-frontend"
    labels {
      App = "spring-frontend"
    }
  }
  spec {
    service_account_name = "${kubernetes_service_account.spring.metadata.0.name}"
    container {
      image = "rberlind/spring-frontend:k8s-auth"
      image_pull_policy = "Always"
      name  = "spring-frontend"
      port {
        container_port = 80
      }
    }
  }

  depends_on = ["kubernetes_service.spring-backend"]
}

resource "kubernetes_service" "spring-frontend" {
  metadata {
    name = "spring-frontend"
  }
  spec {
    selector {
      App = "${kubernetes_pod.spring-frontend.metadata.0.labels.App}"
    }
    port {
      port = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
