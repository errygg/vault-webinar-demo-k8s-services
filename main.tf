provider "kubernetes" {
  host = "${data.terraform_remote_state.k8s_cluster.k8s_endpoint}"
  client_certificate = "${base64decode(data.terraform_remote_state.k8s_cluster.k8s_master_auth_client_certificate)}"
  client_key = "${base64decode(data.terraform_remote_state.k8s_cluster.k8s_master_auth_client_key)}"
  cluster_ca_certificate = "${base64decode(data.terraform_remote_state.k8s_cluster.k8s_master_auth_cluster_ca_certificate)}"
}

data "terraform_remote_state" "k8s_cluster" {
  backend = "atlas"
  config {
    name = "lanceplarsenv2/vault-webinar-demo-k8s-cluster"
  }
}

resource "kubernetes_service_account" "spring" {
  metadata {
    name = "spring"
  }
}

resource "kubernetes_service_account" "vault" {
  metadata {
    name = "vault"
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
      image = "lanceplarsen/spring-vault-demo-k8s"
      image_pull_policy = "Always"
      name  = "spring-frontend"
      port {
        container_port = 8080
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
      port = 8080
      target_port = 8080
    }
    type = "LoadBalancer"
  }
}

