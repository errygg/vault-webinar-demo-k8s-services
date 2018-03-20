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
