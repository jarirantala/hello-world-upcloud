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

# 4. Generate index.html with the correct Backend IP
resource "local_file" "index_html" {
  content = templatefile("${path.module}/src/frontend/index.html", {
    api_ip = kubernetes_service.backend.status[0].load_balancer[0].ingress[0].ip
  })
  filename = "${path.module}/dist/index.html"
}

# 5. Upload index.html to Bucket
# Using curl via null_resource to avoid complex AWS provider setup for a single file
resource "null_resource" "upload_frontend" {
  triggers = {
    file_content = local_file.index_html.content
    bucket_id    = upcloud_managed_object_storage_bucket.frontend_bucket.id
  }

  provisioner "local-exec" {
    command = <<EOT
      # Simple S3 upload via curl
      # Calculate signature or use a tool like s3cmd is usually required, 
      # but for public read access we can try to set ACL. 
      # However, UpCloud Object Storage requires authentication for PUT.
      # For simplicity in this Terraform generation, we assume 's3cmd' or 'aws cli' is NOT installed
      # and use a python one-liner to upload using the generated credentials.
      
      # Workaround for missing python3-venv: use a local directory for packages
      export PYTHONUSERBASE=$(pwd)/.terraform/local_python
      export PATH=$PYTHONUSERBASE/bin:$PATH
      mkdir -p $PYTHONUSERBASE

      # Install pip if missing
      if ! python3 -m pip --version > /dev/null 2>&1; then
        curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        python3 get-pip.py --user --no-warn-script-location || python3 get-pip.py --user --break-system-packages --no-warn-script-location
        rm get-pip.py
      fi

      # Install boto3
      python3 -m pip install --user boto3 --no-warn-script-location || python3 -m pip install --user boto3 --break-system-packages --no-warn-script-location

      python3 -c "
import boto3
import sys

s3 = boto3.client('s3',
    endpoint_url='https://${try(one(upcloud_managed_object_storage.frontend_store.endpoint).domain_name, "")}',
    aws_access_key_id='${upcloud_managed_object_storage_user_access_key.uploader_key.access_key_id}',
    aws_secret_access_key='${upcloud_managed_object_storage_user_access_key.uploader_key.secret_access_key}')

with open('${local_file.index_html.filename}', 'rb') as f:
    s3.upload_fileobj(f, '${upcloud_managed_object_storage_bucket.frontend_bucket.name}', 'index.html', ExtraArgs={'ACL': 'public-read', 'ContentType': 'text/html'})
print('Upload complete')
"
      rm -rf $PYTHONUSERBASE
    EOT
  }

  depends_on = [
    upcloud_managed_object_storage_bucket.frontend_bucket
  ]
}