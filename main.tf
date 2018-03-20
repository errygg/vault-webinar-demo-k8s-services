provider "kubernetes" {
    host = "${var.master_hostname}"
    token = "${var.token}"
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
        namespace = "k8s-go"
    }
}

resource "kubernetes_service_account" "go" {
    metadata {
        name = "go"
        namespace = "k8s-go"
    }
}

resource "kubernetes_service_account" "vault" {
    metadata {
        name = "vault"
        namespace = "k8s-go"
    }
}
