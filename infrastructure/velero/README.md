# Velero Kubernetes Backup

Velero sichert den gesamten Kubernetes-Cluster auf die Synology NAS via MinIO (S3-kompatibel).

## Architektur

```
┌─────────────────────────────────────────────────────────────────┐
│                        k3s Cluster                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐  │
│  │   Velero    │───▶│    MinIO    │───▶│  NFS Volume         │  │
│  │   Server    │    │  (S3-API)   │    │  /volume2/Proxmox/  │  │
│  └─────────────┘    └─────────────┘    │  k8s-backups        │  │
│        │                               └──────────┬──────────┘  │
│  ┌─────┴─────┐                                    │             │
│  │Node-Agent │ (DaemonSet auf allen Worker-Nodes) │             │
│  │ - agent-1 │                                    │             │
│  │ - agent-2 │                                    │             │
│  │ - agent-3 │                                    │             │
│  └───────────┘                                    │             │
└───────────────────────────────────────────────────┼─────────────┘
                                                    │
                                              ┌─────▼─────┐
                                              │ Synology  │
                                              │    NAS    │
                                              │192.168.68.│
                                              │    126    │
                                              └───────────┘
```

## Automatische Backup-Schedules

| Schedule                  | Zeitplan          | Aufbewahrung      | Beschreibung                                             |
| ------------------------- | ----------------- | ----------------- | -------------------------------------------------------- |
| `daily-cluster-backup`    | Täglich 02:00 Uhr | 7 Tage            | Vollständiges Cluster-Backup (alle Namespaces/Resources) |
| `etcd-snapshot` (CronJob) | Täglich 03:00 Uhr | Manuell verwalten | etcd-Snapshots zu MinIO für Cluster-State                |

### Was wird gesichert?

- ✅ Cluster-State: etcd-Snapshots (K3s-Konfiguration, Nodes, Secrets, ConfigMaps, RBAC)
- ✅ Alle Namespaces/Resources: Deployments, Services, PVCs, PVs, Secrets, ConfigMaps
- ✅ Persistent Volumes: Specs + Daten via CSI-Snapshots (Longhorn)
- ✅ Longhorn-Volumes: Daten via Snapshots oder direkte Backups zu MinIO

### Was wird NICHT gesichert?

- ❌ Externe NFS-Daten (z.B. Musik/Bücher auf Synology NAS) – sichere separat
- ❌ Laufende Pods/Logs – werden beim Restore neu gestartet
- ❌ Events (ausgeschlossen zur Performance)

### Restore-Prozess

1. **Cluster wiederherstellen**:

   - Neuen K3s-Cluster aufbauen.
   - etcd-Snapshot laden: `k3s server --cluster-reset --etcd-s3-bucket=velero --etcd-s3-endpoint=minio.velero.svc.cluster.local:9000 --etcd-s3-access-key=minioadmin --etcd-s3-secret-key=homelab-backup-2026 --etcd-s3-region=us-east-1`

2. **Apps wiederherstellen**:
   - `velero restore create --from-backup <backup-name>` – restored automatisch PVs, PVCs, Deployments, Secrets.
   - Zeit: 10-30 Minuten für vollständigen Restore.

### Sicherheit & Robustheit

- Verschlüsselt (Restic in Velero für Daten).
- Speicher gedeckelt durch Retention (7 Tage).
- Automatisch via Schedules.
- Teste regelmäßig in Staging-Umgebung!

Bei Problemen: Logs in Velero (`kubectl logs -n velero`) oder MinIO prüfen.

## Befehle

### Backups anzeigen

```bash
# Alle Backups auflisten
kubectl get backups.velero.io -n velero

# Backup-Details anzeigen
kubectl describe backup <backup-name> -n velero

# Backup-Logs anzeigen
kubectl logs -n velero -l app.kubernetes.io/name=velero --tail=100
```

### Manuelles Backup erstellen

```bash
# Einzelnen Namespace sichern
kubectl create -n velero -f - <<EOF
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: manual-$(date +%Y%m%d-%H%M)
spec:
  includedNamespaces:
    - uptime-kuma
  ttl: 168h  # 7 Tage
  defaultVolumesToFsBackup: true
  storageLocation: default
EOF

# Mehrere Namespaces sichern
kubectl create -n velero -f - <<EOF
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: apps-backup-$(date +%Y%m%d-%H%M)
spec:
  includedNamespaces:
    - uptime-kuma
    - paperless-ngx
    - calibre
    - netbox
  ttl: 720h  # 30 Tage
  defaultVolumesToFsBackup: true
  includeClusterResources: true
  storageLocation: default
EOF

# Komplettes Cluster-Backup
kubectl create -n velero -f - <<EOF
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: full-cluster-$(date +%Y%m%d-%H%M)
spec:
  includedNamespaces:
    - "*"
  excludedNamespaces:
    - kube-system
    - kube-public
    - kube-node-lease
    - velero
  ttl: 2160h  # 90 Tage
  defaultVolumesToFsBackup: true
  includeClusterResources: true
  storageLocation: default
EOF
```

### Backup wiederherstellen (Restore)

```bash
# Namespace aus Backup wiederherstellen
kubectl create -n velero -f - <<EOF
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: restore-$(date +%Y%m%d-%H%M)
spec:
  backupName: <backup-name>
  includedNamespaces:
    - uptime-kuma
  restorePVs: true
EOF

# Restore-Status prüfen
kubectl get restore -n velero
kubectl describe restore <restore-name> -n velero
```

### Schedules verwalten

```bash
# Schedules anzeigen
kubectl get schedules.velero.io -n velero

# Schedule pausieren
kubectl patch schedule velero-daily-backup -n velero --type merge -p '{"spec":{"paused":true}}'

# Schedule fortsetzen
kubectl patch schedule velero-daily-backup -n velero --type merge -p '{"spec":{"paused":false}}'
```

### Backup-Status prüfen

```bash
# Storage Location Status
kubectl get backupstoragelocation -n velero

# Letzte Backups mit Status
kubectl get backups.velero.io -n velero --sort-by=.metadata.creationTimestamp

# Fehlgeschlagene Backups finden
kubectl get backups.velero.io -n velero -o jsonpath='{range .items[?(@.status.phase!="Completed")]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'
```

## Konfiguration anpassen

Die Backup-Konfiguration befindet sich in `apps/production/velero.yaml`.

### Schedule ändern

```yaml
schedules:
  daily-backup:
    schedule: "0 2 * * *" # Cron: Minute Stunde Tag Monat Wochentag
    template:
      ttl: 720h # Aufbewahrung in Stunden (720h = 30 Tage)
      includedNamespaces:
        - "*" # Alle Namespaces
      excludedNamespaces:
        - kube-system # System-Namespaces ausschließen
```

### Cron-Beispiele

| Ausdruck       | Bedeutung             |
| -------------- | --------------------- |
| `0 2 * * *`    | Täglich um 02:00 Uhr  |
| `0 3 * * 0`    | Sonntags um 03:00 Uhr |
| `0 */6 * * *`  | Alle 6 Stunden        |
| `30 1 * * 1-5` | Mo-Fr um 01:30 Uhr    |

### TTL (Aufbewahrungszeit)

| Wert    | Dauer   |
| ------- | ------- |
| `24h`   | 1 Tag   |
| `168h`  | 7 Tage  |
| `720h`  | 30 Tage |
| `2160h` | 90 Tage |
| `8760h` | 1 Jahr  |

## Troubleshooting

### Backup schlägt fehl

```bash
# Velero Logs prüfen
kubectl logs -n velero deployment/velero --tail=200

# Node-Agent Logs prüfen (für Volume-Backups)
kubectl logs -n velero -l name=node-agent --tail=100

# Backup-Details mit Fehlern
kubectl describe backup <backup-name> -n velero
```

### MinIO Verbindung prüfen

```bash
# MinIO Pod Status
kubectl get pods -n velero -l app=minio

# Storage Location Validierung
kubectl get backupstoragelocation -n velero -o wide
```

### Velero neu starten

```bash
kubectl rollout restart deployment/velero -n velero
kubectl rollout restart daemonset/node-agent -n velero
```

## Disaster Recovery

### Komplettes Cluster wiederherstellen

1. **Neuen k3s Cluster aufsetzen**
2. **Velero installieren** (via ArgoCD oder manuell)
3. **MinIO mit NFS-Storage verbinden** (gleiche NAS-Freigabe)
4. **Backups auflisten:**
   ```bash
   kubectl get backups.velero.io -n velero
   ```
5. **Restore durchführen:**
   ```bash
   kubectl create -n velero -f - <<EOF
   apiVersion: velero.io/v1
   kind: Restore
   metadata:
     name: disaster-recovery
   spec:
     backupName: velero-daily-backup-20260104020000
     includedNamespaces:
       - "*"
     restorePVs: true
   EOF
   ```

## Dateispeicherort auf NAS

Die Backups werden auf der Synology NAS gespeichert:

- **NFS-Pfad:** `/volume2/Proxmox/k8s-backups`
- **NAS-IP:** `192.168.68.126`
- **Bucket:** `velero`

Die Backup-Daten können auch direkt auf der NAS eingesehen werden.
