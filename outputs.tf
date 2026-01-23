output "kubernetes_cluster_host" {
  sensitive = true
  value = yamldecode(data.upcloud_kubernetes_cluster.main.kubeconfig).clusters[0].cluster.server
}

output "backend_load_balancer_ip" {
  value = kubernetes_service.backend.status[0].load_balancer[0].ingress[0].hostname
}

output "frontend_url" {
  description = "URL to access the application"
  value       = "http://${try(one(upcloud_managed_object_storage.frontend_store.endpoint).domain_name, "${var.object_storage_region}.upcloudobjects.com")}/${upcloud_managed_object_storage_bucket.frontend_bucket.name}/index.html"
}