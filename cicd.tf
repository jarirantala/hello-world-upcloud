# 1. Namespace for the runner (optional but recommended)
resource "kubernetes_namespace" "cicd" {
  metadata {
    name = "github-runner"
  }
}

# 2. Secret to store the GitHub Token
resource "kubernetes_secret" "runner_secret" {
  metadata {
    name      = "runner-token"
    namespace = kubernetes_namespace.cicd.metadata[0].name
  }

  data = {
    "RUNNER_TOKEN" = var.github_token
  }

  type = "Opaque"
}

# 3. GitHub Actions Runner Deployment
# Using the summerwind/actions-runner image for a simple setup
resource "kubernetes_deployment" "github_runner" {
  metadata {
    name      = "github-runner"
    namespace = kubernetes_namespace.cicd.metadata[0].name
    labels = {
      app = "github-runner"
    }
  }

  wait_for_rollout = false

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "github-runner"
      }
    }

    template {
      metadata {
        labels = {
          app = "github-runner"
        }
      }

      spec {
        container {
          name  = "runner"
          image = "summerwind/actions-runner:latest"

          env {
            name  = "REPO_URL"
            value = var.github_repo_url
          }

          env {
            name = "RUNNER_TOKEN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.runner_secret.metadata[0].name
                key  = "RUNNER_TOKEN"
              }
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          # Using DinD (Docker in Docker) for the runner if needed for building images
          # This requires privileged mode
          security_context {
            privileged = true
          }
        }
      }
    }
  }
}
