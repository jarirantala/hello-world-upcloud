resource "upcloud_managed_database_valkey" "valkey" {
  name  = "valkey-${var.environment}"
  plan  = var.valkey_plan
  zone  = var.region
  title = "Valkey Storage"

  network {
    name   = "k8s-db-link"
    type   = "private"
    uuid   = upcloud_network.k8s_net.id
    family = "IPv4"
  }

  properties {
    public_access = false
  }
}

resource "upcloud_managed_database_user" "valkey_user" {
  service  = upcloud_managed_database_valkey.valkey.id
  username = "app_user"
}
