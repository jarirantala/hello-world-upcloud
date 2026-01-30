# 1. ConfigMap containing the Python code
# This avoids needing to build and push a Docker image for a simple Hello World
resource "kubernetes_config_map" "app_code" {
  metadata {
    name = "backend-code"
  }

  data = {
    "app.py" = file("${path.module}/src/backend/app.py")
  }

  depends_on = [
    data.upcloud_kubernetes_cluster.main,
    time_sleep.wait_for_k8s
  ]
}

# 2. Deployment
resource "kubernetes_deployment" "backend" {
  metadata {
    name = "hello-backend"
    labels = {
      app = "hello-world"
    }
  }

  wait_for_rollout = false

  spec {
    replicas                  = 1
    progress_deadline_seconds = 600

    selector {
      match_labels = {
        app = "hello-world"
      }
    }

    template {
      metadata {
        labels = {
          app = "hello-world"
        }
        annotations = {
          # This forces a rolling restart whenever the code changes
          "config-hash" = sha256(jsonencode(kubernetes_config_map.app_code.data))
        }
      }

      spec {
        container {
          image = "python:3.9-alpine"
          name  = "python-app"

          # Use native Python server - starts instantly with zero dependencies!
          # We add 'redis' library via pip to support Valkey
          command = ["sh", "-c", "pip install redis && python /app/app.py"]

          port {
            container_port = 5000
          }

          env {
            name  = "FRONTEND_URL"
            value = "http://${element(concat([for e in upcloud_managed_object_storage.frontend_store.endpoint : e.domain_name], ["${upcloud_managed_object_storage.frontend_store.name}.upcloudobjects.com"]), 0)}"
          }

          env {
            name  = "VALKEY_HOST"
            value = upcloud_managed_database_valkey.valkey.service_host
          }

          env {
            name  = "VALKEY_PORT"
            value = upcloud_managed_database_valkey.valkey.service_port
          }

          env {
            name  = "VALKEY_USER"
            value = upcloud_managed_database_user.valkey_user.username
          }

          env {
            name  = "VALKEY_PASSWORD"
            value = upcloud_managed_database_user.valkey_user.password
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }

          volume_mount {
            name       = "code-volume"
            mount_path = "/app"
          }
        }

        volume {
          name = "code-volume"
          config_map {
            name = kubernetes_config_map.app_code.metadata[0].name
          }
        }
      }
    }
  }
}

# 3. Service (LoadBalancer)
resource "kubernetes_service" "backend" {
  metadata {
    name = "hello-service-v2"
  }
  spec {
    selector = {
      app = kubernetes_deployment.backend.spec[0].selector[0].match_labels.app
    }
    port {
      port        = 80
      target_port = 5000
    }
    type = "LoadBalancer"
  }
}
