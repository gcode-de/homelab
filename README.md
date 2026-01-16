# Homelab K3s Cluster

GitOps-managed K3s cluster mit ArgoCD.

## Struktur

- `bootstrap/` - ArgoCD Installation
- `infrastructure/` - Basis-Komponenten (Ingress, Cert-Manager, etc.)
- `apps/` - Produktive Anwendungen

## Deployment

Alles wird automatisch via ArgoCD deployed.
