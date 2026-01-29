# API Specification

## 1. Endpoint: Get Greeting
* **URL:** `http://<load-balancer-ip>/api/hello`
* **Method:** `GET`

### Request Headers
* `Origin`: `http://<bucket-name>.fi-hel2.upcloudobjects.com`

### Response Headers (Critical)
* `Access-Control-Allow-Origin`: `*` (or the specific storage domain)
* `Content-Type`: `application/json`

### Response Body
```json
{
  "message": "Hello from UpCloud Kubernetes!",
  "status": "success"
}