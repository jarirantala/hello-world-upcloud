output "kubernetes_cluster_host" {
  sensitive = true
  value = yamldecode(data.upcloud_kubernetes_cluster.main.kubeconfig).clusters[0].cluster.server
}

output "valkey_host" {
  value = upcloud_managed_database_valkey.valkey.service_host
}

output "valkey_port" {
  value = upcloud_managed_database_valkey.valkey.service_port
}

output "valkey_user" {
  value = upcloud_managed_database_user.valkey_user.username
}

output "valkey_password" {
  value     = upcloud_managed_database_user.valkey_user.password
  sensitive = true
}

output "backend_load_balancer_ip" {
  value = kubernetes_service.backend.status[0].load_balancer[0].ingress[0].hostname
}

output "frontend_url" {
  description = "URL to access the application"
  value       = "http://${element(concat([for e in upcloud_managed_object_storage.frontend_store.endpoint : e.domain_name], ["${upcloud_managed_object_storage.frontend_store.name}.upcloudobjects.com"]), 0)}/${upcloud_managed_object_storage_bucket.frontend_bucket.name}/index.html"
}

output "kubeconfig" {
  value     = data.upcloud_kubernetes_cluster.main.kubeconfig
  sensitive = true
}