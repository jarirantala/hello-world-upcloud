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

  spec {
    replicas = 2

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
      }

      spec {
        container {
          image = "python:3.9-alpine"
          name  = "python-app"
          
          # Install dependencies at runtime for this demo
          command = ["/bin/sh", "-c", "pip install flask flask-cors && python /app/app.py"]

          port {
            container_port = 5000
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
    name = "hello-service"
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