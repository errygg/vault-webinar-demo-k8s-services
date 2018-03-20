provider "kubernetes" {
    host = "${var.master_hostname}"
    username = "${var.master_usernmae}"
    password = "${var.master_password}"
}

${var.master_username}

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

resource "kubernetes_service_account" "go" {
    metadata {
        name = "go"
    }
}

resource "kubernetes_service_account" "vault" {
    metadata {
        name = "vault"
    }
}
