resource "kubernetes_replication_controller" "go-frontend" {
  metadata {
    name = "go-frontend"
    labels {
      App = "go-frontend"
    }
  }

  spec {
    replicas = 1
    selector {
      App = "go-frontend"
    }
    template {
    service_account_name = "${kubernetes_service_account.go.metadata.0.name}"
    container {
        image = "lanceplarsen/go-vault-demo"
        image_pull_policy = "Always"
        name = "go"
        volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name = "${kubernetes_service_account.go.default_secret_name}"
            read_only = true
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
    namespace = "k8s-go"
  }
  data {
    config = <<EOF
    [database]
    server="llarsenvaultdb.cihgglcplvpp.us-east-1.rds.amazonaws.com:5432"
    name="postgres"
    role="database/creds/order"
    [vault]
    server="http://34.200.226.105:8200"
    authentication="kubernetes"
    role="order"
    service-account-token-file="/var/run/secrets/kubernetes.io/serviceaccount/token"
EOF
  }
}
