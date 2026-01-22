# Infrastructure Implementation Spec

## 1. Project Structure
```text
.
├── main.tf                 # UpCloud Provider, Network, Object Storage Service
├── kubernetes.tf           # UKS Cluster Definition
├── frontend.tf             # Bucket & HTML Upload
├── backend.tf              # Kubernetes Deployment & Service
├── variables.tf
├── outputs.tf
└── src/
    ├── frontend/
    │   └── index.html
    └── backend/
        └── app.py          # Python Flask App (w/ CORS support)
        └── Dockerfile