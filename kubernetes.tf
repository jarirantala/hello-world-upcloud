resource "upcloud_kubernetes_cluster" "main" {
  name    = "hello-cluster-${var.environment}"
  network = upcloud_network.k8s_net.id
  zone    = var.region
  control_plane_ip_filter = ["0.0.0.0/0"]
}

resource "upcloud_kubernetes_node_group" "group" {
  cluster    = upcloud_kubernetes_cluster.main.id
  node_count = 2
  name       = "worker-group"
  plan       = "1xCPU-2GB"

  labels = {
    env = var.environment
  }
}

resource "time_sleep" "wait_for_k8s" {
  create_duration = "60s"

  depends_on = [upcloud_kubernetes_cluster.main]
}

data "upcloud_kubernetes_cluster" "main" {
  id = upcloud_kubernetes_cluster.main.id
}

# Configure the Kubernetes provider to use the cluster credentials
provider "kubernetes" {
  host                   = yamldecode(data.upcloud_kubernetes_cluster.main.kubeconfig).clusters[0].cluster.server
  client_certificate     = base64decode(yamldecode(data.upcloud_kubernetes_cluster.main.kubeconfig).users[0].user["client-certificate-data"])
  client_key             = base64decode(yamldecode(data.upcloud_kubernetes_cluster.main.kubeconfig).users[0].user["client-key-data"])
  cluster_ca_certificate = base64decode(yamldecode(data.upcloud_kubernetes_cluster.main.kubeconfig).clusters[0].cluster["certificate-authority-data"])
}