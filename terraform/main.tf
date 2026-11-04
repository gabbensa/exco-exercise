terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.5"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

provider "kind" {}

# Local Kubernetes cluster: 1 control-plane + 2 workers.
# Ports 80/443 mapped to the host so the ingress controller
# is reachable from the browser on this laptop.
resource "kind_cluster" "exco" {
  name           = "exco"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }

    node { role = "worker" }
    node { role = "worker" }
  }
}

# Argo CD — server-side apply: the CRDs are too large for client-side apply annotations
resource "null_resource" "argocd" {
  depends_on = [kind_cluster.exco]
  provisioner "local-exec" {
    command = <<-EOT
      kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
      kubectl apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    EOT
  }
}

# Ingress controller — pinned release tag (main branch moved, lesson: always pin versions)
resource "null_resource" "ingress_nginx" {
  depends_on = [kind_cluster.exco]
  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.15.1/deploy/static/provider/kind/deploy.yaml"
  }
}
