resource "kubernetes_replication_controller" "go-frontend" {
  metadata {
    name = "go-frontend"
    labels {
      App = "go-frontend"
    }
  }

  spec {
    replicas = 0
    selector {
      App = "go-frontend"
    }
    template {
    service_account_name = "${kubernetes_service_account.go.metadata.0.name}"
    container {
        image = "${var.go_docker_container}"
        image_pull_policy = "Always"
        name = "go"
        volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name = "${kubernetes_service_account.go.default_secret_name}"
        }
        volume_mount {
            mount_path = "/app/config.toml"
            sub_path = "config.toml"
            name = "${kubernetes_config_map.go.metadata.0.name}"
        }
        port {
            container_port = 3000
        }
    }
    volume {
        name = "${kubernetes_service_account.go.default_secret_name}"
        secret {
            secret_name = "${kubernetes_service_account.go.default_secret_name}"
        }
    }
    volume {
        name = "${kubernetes_config_map.go.metadata.0.name}"
        config_map {
            name = "go"
            items {
                key = "config"
                path =  "config.toml"
            }
        }
    }
    }
  }
}

resource "kubernetes_service" "go-frontend" {
    metadata {
        name = "go-frontend"
    }
    spec {
        selector {
            App = "${kubernetes_replication_controller.go-frontend.metadata.0.labels.App}"
        }
        port {
            port = 3000
            target_port = 3000
        }
        type = "LoadBalancer"
    }
}

resource "kubernetes_config_map" "go" {
  metadata {
    name = "go"
  }
  data {
    config = <<EOF
    [database]
    server="${var.postgres_host}:${var.postgres_port}"
    name="${var.postgres_instance}"
    role="database/creds/${var.postgres_role}"
    [vault]
    host="${var.vault_host}"
    port="${var.vault_port}"
    scheme="${var.vault_scheme}"
    authentication="kubernetes"
    credential="/var/run/secrets/kubernetes.io/serviceaccount/token"
    role="${var.vault_role}"
EOF
  }
}
