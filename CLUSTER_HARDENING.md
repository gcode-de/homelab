# Homelab Cluster Härtung & Best Practices

**Letztes Update:** 10. Februar 2026  
**Cluster-Status:** ✅ Healthy

## Erkannte Probleme & Lösungen

### 1. ArgoCD Multi-Domain Redirect Loop
**Problem:** ArgoCD redirects endlos zwischen `argocd.samuelgesang.de` (Tunnel) und `argocd.homelab.local` (lokal)  
**Root Cause:** `backend-protocol: HTTP` mit `url: https://...` in ArgoCD ConfigMap + SSL-Redirect-Annotationen verursachen Konfusion

**Lösung:**
- Externe Ingress (Tunnel): `backend-protocol: HTTP` + `ssl-redirect: true`
- Lokale Ingress (mkcert): `backend-protocol: HTTPS` + `ssl-redirect: false` + `proxy-ssl-verify: off`
- **Wichtig:** Keine `url` in `argocd-cm` - ArgoCD nutzt dann Req Host Header

**Zukünftige Vorbeugung:**
```yaml
# ingress-local.yaml für ArgoCD
nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
nginx.ingress.kubernetes.io/proxy-ssl-verify: "off"
nginx.ingress.kubernetes.io/ssl-redirect: "false"
```

---

### 2. Terminating Pods bleiben hängen
**Problem:** Pods können nicht ordnungsgemäß terminiert werden, besonders auf NotReady Nodes  
**Root Cause:** Grace Period Timeout bei forceful deletions + Node Kubelet nicht erreichbar

**Lösung:** 
```bash
kubectl delete pod POD_NAME --grace-period=0 --force
```

**Zukünftige Vorbeugung:**

a) **Pod Disruption Budgets (PDB)** für kritische Services:
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: argocd-pdb
  namespace: argocd
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-server
```

b) **Preemption Policy** für sauberes Herunterfahren:
```yaml
spec:
  terminationGracePeriodSeconds: 30
  preemptionPolicy: PreemptLowerPriority
```

---

### 3. Node NotReady nach Cluster-Restart
**Problem:** k3s-server-3 hatte "Kubelet stopped posting node status" Status  
**Root Cause:** Kubelet nicht erreichbar von Control Plane nach Neustart

**Lösungen getestet:**
- ✅ Warten (selbst behoben nach ~10 min)
- ✅ ArgoCD Neustart beschleunigte Recovery
- ❌ Node restart war nicht nötig

**Zukünftige Vorbeugung:**
- Monitoring für NotReady Nodes (PrometheusRule: `node-health-alerts`)
- Automatisches Notifier-System für > 5 min NotReady Status
- Descheduler konfigurieren um Pods von NotReady Nodes zu evictieren

---

### 4. Velero BackupRepositories von gelöschten Apps
**Problem:** Velero läuft Maintenance-Jobs für nicht mehr existierende Namespaces  
**Root Cause:** BackupRepository CRDs werden nicht automatisch gelöscht wenn Apps gelöscht werden

**Lösung:**
```bash
# Automatisiert alle 24h ausführen:
bash /Users/gp/Developer/homelab/scripts/velero-cleanup.sh
```

**Integration:** Als CronJob deployen:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: velero-cleanup
  namespace: velero
spec:
  schedule: "0 2 * * *"  # Täglich 2 Uhr nachts
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: velero
          containers:
          - name: cleanup
            image: bitnami/kubectl:latest
            command:
            - /bin/sh
            - -c
            - |
              kubectl delete jobs -n velero --field-selector status.successful=0
```

---

## Präventions-Checkliste für zukünftige Restarts

### Vor Cluster-Restart
- [ ] `kubectl get nodes` - Alle Nodes Ready prüfen
- [ ] `kubectl top nodes` - Memory/CPU Auslastung prüfen
- [ ] `kubectl get pods -A --field-selector status.phase=Failed` - Fehlerhafte Pods beheben
- [ ] Backup der etcd: `velero backup create pre-restart-backup`

### Nach Cluster-Restart
- [ ] `kubectl wait --for=condition=Ready nodes --all --timeout=600s`
- [ ] `kubectl get pods -A | grep Terminating` - Hängende Pods force-löschen
- [ ] `kubectl get application -n argocd` - Alle Apps sollten Healthy sein
- [ ] Velero Cleanup Script ausführen
- [ ] Monitoring prüfen: `https://grafana.homelab.local`

---

## Session-Summary (10. Februar 2026)

**Gelöste Probleme:**
1. ✅ Root App stuck → PVC neu erstellt (Longhorn Volume Attachment)
2. ✅ Portainer `homelab.local` zugänglich → Lokale Ingress + Secret hinzugefügt
3. ✅ ArgoCD Redirect-Loop → Backend-Protocol auf HTTPS + Config angepasst
4. ✅ k3s-server-3 NotReady → Auto-Recovery nach ArgoCD Restart
5. ✅ Terminating Pods → Force-deleted
6. ✅ Velero Error Jobs → Gelöscht

**Neuerungen:**
- PrometheusRules für Node Health Monitoring
- Velero Cleanup Script
- ArgoCD Multi-Domain Ingress Best Practices dokumentiert

---

## Monitoring & Alerting

### Wichtige Prometheus Queries:
```promql
# Alle NotReady Nodes
kube_node_status_condition{condition="Ready",status="true"} == 0

# Stuck Terminating Pods
count(kube_pod_deletion_timestamp > 0) > 0

# Velero Job Fehlerrate
increase(velero_backup_total{phase="Failed"}[1h]) > 0

# ArgoCD Application Health
argocd_app_health_status{health_status!="Healthy"} > 0
```

---

## Quick-Fix Befehle

```bash
# Node neustarten (falls wirklich nötig)
kubectl drain NODE_NAME --ignore-daemonsets --delete-local-data

# Alle problematischen Pods in Namespace löschen
kubectl get pods -n NAMESPACE -o name | xargs -I {} kubectl delete {} --force --grace-period=0

# ArgoCD Logs debuggen
kubectl logs -n argocd deployment/argocd-server -f

# ETCD Health prüfen
kubectl -n kube-system exec etcd-k3s-server-1 -- etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key endpoint health
```
