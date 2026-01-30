# Technical Design Document (Architecture)

## 1. High-Level Diagram
```mermaid
graph LR
    User[Browser] -- HTTP Request --> Storage[UpCloud Object Storage\n(Hosts index.html)]
    User -- AJAX (Fetch) --> LB[UpCloud Load Balancer]
    LB -- Route /api/hello --> K8s[Kubernetes Cluster\n(Python Backend Pod)]
    K8s -- Read/Write --> Valkey[(UpCloud Managed\nValkey DB)]
```