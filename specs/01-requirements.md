# Product Requirement Document (PRD) - UpCloud Hybrid

## 1. Overview
The application is a "Hello World" web page. The static content (HTML/JS) is hosted on UpCloud Object Storage (low cost, high availability), while the dynamic logic runs on UpCloud Managed Kubernetes.

## 2. User Stories
* **As a user**, I want to visit a public URL (Object Storage link) to load the application.
* **As a user**, I want the page to display a greeting fetched from the backend API.

## 3. Functional Requirements
* **Frontend:**
    * Host `index.html` on UpCloud Managed Object Storage.
    * Files must be publicly readable (Anonymous access).
    * JavaScript must fetch data from the Kubernetes Load Balancer IP.
* **Backend:**
    * Python container running on UpCloud Managed Kubernetes (UKS).
    * Expose a public API endpoint via a Load Balancer.
    * **Data Storage:** Scalable Valkey instance (managed service) for persistent greeting state or hit counters.
    * **CORS:** Must allow requests from the Object Storage domain.

## 4. Non-Functional Requirements
* **Infrastructure:** Defined entirely in Terraform.
* **Region:** `fi-hel2` (Helsinki).