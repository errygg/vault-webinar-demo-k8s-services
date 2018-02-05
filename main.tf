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
            name = "spring"
            volume_mount {
                mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
                name = "${kubernetes_service_account.spring.default_secret_name}"
                read_only = true
            }
            volume_mount {
                mount_path = "/bootstrap.yaml"
                sub_path = "bootstrap.yaml"
                name = "${kubernetes_config_map.spring.name}"
            }
            port {
                container_port = 8080
            }
        }
        volume {
            name = "${kubernetes_service_account.spring.default_secret_name}"
            secret {
                secret_name = "${kubernetes_service_account.spring.default_secret_name}"
            }
        }
        volume {
            name = "${kubernetes_config_map.spring.name}"
            config_map {
                name = "spring"
                items {
                    key = "config"
                    path =  "bootstrap.yaml"
                }
            }
        }       
    }
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

resource "kubernetes_config_map" "spring" {
  metadata {
    name = "spring-config"
  }
  data {
    config = <<EOF
---
spring.cloud.vault:
    authentication: KUBERNETES
    kubernetes:
        role: order
        service-account-token-file: /var/run/secrets/kubernetes.io/serviceaccount/token
    host: 34.200.226.105
    port: 8200
    scheme: http
    fail-fast: true
    config.lifecycle.enabled: true
    database:
        enabled: true
        role: order
        backend: database
spring.datasource:
    url: jdbc:postgresql://llarsenvaultdb.cihgglcplvpp.us-east-1.rds.amazonaws.com:5432/postgres
EOF
  }
}
