# Task Manager Application

## Overview

This repository contains a **Task Manager application** with:

- **Backend**: Flask + PostgreSQL
- **Frontend**: Static HTML + JS
- **Infrastructure**: Kubernetes, Terraform, Helm, Karpenter, Nginx Ingress, Cert-Manager
- **Local development**: Docker Compose for frontend, backend, and PostgreSQL

---

## Folder Structure

├── application/ # Application source code
│ ├── backend/ # Backend Flask app
│ ├── frontend/ # Frontend static files and Dockerfile
│ └── docker-compose.yaml
├── apps/ # argocd apps 
├── devops-manifest/ # Helm charts for backend, frontend, ingress, karpenter, postgres
├── Infrastructure/ # Terraform modules and environment configs
└── README.md # This file

---

## Prerequisites

- **Terraform >= 1.5**
- **kubectl**
- **AWS CLI** configured
- **Docker & Docker Compose**
- **Helm**

---

## Running on Kubernetes (Terraform + Helm)

### 1. Terraform Setup

1. Navigate to environment folder:

```bash
cd Infrastructure/prod
terraform init
terraform apply -target=module.vpc it must as fisrt
terraform apply
```

