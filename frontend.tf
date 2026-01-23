resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# 1. Object Storage Service
resource "upcloud_managed_object_storage" "frontend_store" {
  name   = "frontend-store-${var.environment}-${random_string.suffix.result}"
  region = var.object_storage_region
  configured_status = "started"
}

# 2. Create a Bucket
resource "upcloud_managed_object_storage_bucket" "frontend_bucket" {
  service_uuid = upcloud_managed_object_storage.frontend_store.id
  name         = "hello-world-frontend-${random_string.suffix.result}"
}

# 3. Create User/Access Keys for uploading
resource "upcloud_managed_object_storage_user" "uploader" {
  service_uuid = upcloud_managed_object_storage.frontend_store.id
  username     = "uploader"
}

resource "upcloud_managed_object_storage_user_access_key" "uploader_key" {
  service_uuid = upcloud_managed_object_storage.frontend_store.id
  username     = upcloud_managed_object_storage_user.uploader.username
  status       = "Active"
}

resource "upcloud_managed_object_storage_policy" "uploader_policy" {
  service_uuid = upcloud_managed_object_storage.frontend_store.id
  name         = "uploader-policy-${random_string.suffix.result}"
  document     = urlencode(jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          "arn:aws:s3:::${upcloud_managed_object_storage_bucket.frontend_bucket.name}",
          "arn:aws:s3:::${upcloud_managed_object_storage_bucket.frontend_bucket.name}/*"
        ]
      }
    ]
  }))
}

resource "upcloud_managed_object_storage_user_policy" "uploader_policy_attach" {
  service_uuid = upcloud_managed_object_storage.frontend_store.id
  username     = upcloud_managed_object_storage_user.uploader.username
  name         = upcloud_managed_object_storage_policy.uploader_policy.name
}

# 4. Wait for Policy Attachment
# Ensure permissions are propagated before attempting upload
resource "time_sleep" "wait_for_policy" {
  create_duration = "15s"
  depends_on      = [upcloud_managed_object_storage_user_policy.uploader_policy_attach]
}

# 4. Generate index.html with the correct Backend IP
resource "local_file" "index_html" {
  content = templatefile("${path.module}/src/frontend/index.html", {
    api_ip = kubernetes_service.backend.status[0].load_balancer[0].ingress[0].hostname
  })
  filename = "${path.module}/dist/index.html"
}

# 5. Upload index.html to Bucket using local AWS CLI
resource "null_resource" "upload_frontend" {
  triggers = {
    file_content = local_file.index_html.content
    bucket_id    = upcloud_managed_object_storage_bucket.frontend_bucket.id
  }

  provisioner "local-exec" {
    command = <<EOT
      export AWS_ACCESS_KEY_ID="${upcloud_managed_object_storage_user_access_key.uploader_key.access_key_id}"
      export AWS_SECRET_ACCESS_KEY="${upcloud_managed_object_storage_user_access_key.uploader_key.secret_access_key}"
      export AWS_DEFAULT_REGION="${var.object_storage_region}"
      export AWS_REQUEST_CHECKSUM_CALCULATION="when_required"
      export AWS_RESPONSE_CHECKSUM_VALIDATION="when_required"
      
      # Create temporary config to disable payload signing (fixes XAmzContentSHA256Mismatch)
      export AWS_CONFIG_FILE=$(mktemp)
      echo "[default]" > "$AWS_CONFIG_FILE"
      echo "s3 =" >> "$AWS_CONFIG_FILE"
      echo "    payload_signing_enabled = false" >> "$AWS_CONFIG_FILE"

      if aws s3 cp "${local_file.index_html.filename}" \
        "s3://${upcloud_managed_object_storage_bucket.frontend_bucket.name}/index.html" \
        --endpoint-url "https://${try(one(upcloud_managed_object_storage.frontend_store.endpoint).domain_name, "${var.object_storage_region}.upcloudobjects.com")}" \
        --acl public-read \
        --content-type text/html; then
        rm -f "$AWS_CONFIG_FILE"
      else
        rm -f "$AWS_CONFIG_FILE"
        exit 1
      fi
    EOT
  }

  depends_on = [
    time_sleep.wait_for_policy
  ]
}