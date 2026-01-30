terraform {
  required_providers {
    upcloud = {
      source  = "UpCloudLtd/upcloud"
      version = "5.33.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    local = {
      source = "hashicorp/local"
    }
    null = {
      source = "hashicorp/null"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

provider "upcloud" {
  token = var.upcloud_token
}

# Router for the Private Network (Required by Managed Databases)
resource "upcloud_router" "k8s_router" {
  name = "k8s-router-${var.environment}"
}

# Network for the Kubernetes Cluster
resource "upcloud_network" "k8s_net" {
  name   = "k8s-network-${var.environment}"
  zone   = var.region
  router = upcloud_router.k8s_router.id

  ip_network {
    address = "172.16.0.0/24"
    dhcp    = true
    family  = "IPv4"
  }
}