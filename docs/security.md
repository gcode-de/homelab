# Sicherheitsprinzipien

## Netzwerkgrenze

Der Cluster ist für den Zugriff aus dem privaten Heimnetz ausgelegt. Anwendungen erhalten ausschließlich lokale Hostnamen unter `*.homelab.local`; die MetalLB-Adressen stammen aus einem privaten RFC-1918-Netz.

- keine Portweiterleitung vom Internet zu ingress-nginx oder zur Kubernetes API
- keine öffentliche LoadBalancer-IP und kein öffentlich erreichbarer Ingress
- administrativer Zugriff nur aus dem vertrauenswürdigen LAN oder über einen separat abgesicherten VPN-Zugang
- `ClusterIP` als Standard-Service-Typ; `LoadBalancer` nur für den zentralen Ingress
- Firewall-Regeln am Router sind die maßgebliche äußere Schutzschicht

cert-manager kann DNS-01 für Zertifikate verwenden, ohne einen eingehenden Internetzugriff auf den Cluster zu öffnen. Ein öffentlicher DNS-Name oder ein Zertifikat allein stellt keine Netzwerkverbindung her.

Prüfung der exponierten Ressourcen:

```bash
kubectl get services -A --field-selector spec.type=LoadBalancer
kubectl get ingress -A
kubectl get nodes -o wide
```

## Secret-Management

Klartext-Secrets gehören weder in Manifeste noch in Dokumentation, Commits, Shell-Skripte oder Screenshots. Im Repository dürfen nur folgende Formen vorkommen:

- Referenzen auf bereits vorhandene Kubernetes Secrets
- mit dem clustergebundenen öffentlichen Schlüssel verschlüsselte SealedSecrets
- eindeutig erkennbare Platzhalter wie `<STRONG_RANDOM_PASSWORD>`

Unversiegelte Dateien enden auf `.unsealed.yaml` und werden durch `.gitignore` ausgeschlossen. Das Vorgehen zum Versiegeln ist in `infrastructure/common/secrets/README.md` beschrieben.

### Erforderliche, nicht eingecheckte Secrets

| Namespace | Secret | Schlüssel | Verbraucher |
| --- | --- | --- | --- |
| `monitoring` | `grafana-admin-credentials` | `admin-user`, `admin-password` | Grafana |
| `velero` | `minio-credentials` | `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD` | MinIO und Setup-Job |
| `velero` | `velero-credentials` | `cloud` | Velero S3-Client |
| `kube-system` | `etcd-s3-credentials` | `access-key`, `secret-key` | etcd-Snapshot-CronJob |

Die MinIO-, Velero- und etcd-Zugangsdaten müssen dasselbe S3-Konto abbilden, werden wegen der Namespace-Grenze aber als getrennte Kubernetes Secrets bereitgestellt. Beispiel mit redigierten Werten:

```bash
kubectl create secret generic minio-credentials \
  --namespace velero \
  --from-literal=MINIO_ROOT_USER='<S3_ACCESS_KEY>' \
  --from-literal=MINIO_ROOT_PASSWORD='<S3_SECRET_KEY>'

kubectl create secret generic velero-credentials \
  --namespace velero \
  --from-file=cloud=/path/outside/repository/velero-cloud-credentials

kubectl create secret generic etcd-s3-credentials \
  --namespace kube-system \
  --from-literal=access-key='<S3_ACCESS_KEY>' \
  --from-literal=secret-key='<S3_SECRET_KEY>'
```

Die Datei für `velero-credentials` hat lokal dieses Format:

```ini
[default]
aws_access_key_id=<S3_ACCESS_KEY>
aws_secret_access_key=<S3_SECRET_KEY>
```

Produktiv sollten die Secrets als SealedSecrets verwaltet oder unmittelbar aus einem Secret-Manager erzeugt werden. Zugriffsrechte werden nach dem Least-Privilege-Prinzip vergeben und regelmäßig überprüft.

## Schutz der Workloads

- Images auf feste Versionen oder Digests pinnen; `latest` vermeiden.
- Pods ohne Root-Rechte, mit read-only Root-Dateisystem und `seccompProfile: RuntimeDefault` betreiben, soweit das Image dies unterstützt.
- CPU- und Memory-Requests sowie Limits definieren.
- RBAC auf benötigte Verben und Ressourcen begrenzen.
- NetworkPolicies für Anwendungen ergänzen, sobald der eingesetzte CNI sie zuverlässig erzwingt.
- Backups verschlüsseln, Restore-Tests durchführen und Backup-Zugänge getrennt rotieren.

## Reaktion auf versehentlich veröffentlichte Secrets

Das Löschen aus dem aktuellen Branch entfernt ein Secret nicht aus der Git-Historie. Bei einem Fund gilt daher:

1. betroffene Zugangsdaten sofort sperren beziehungsweise rotieren
2. abhängige Kubernetes Secrets aktualisieren und Workloads neu starten
3. Zugriffslogs auf Missbrauch prüfen
4. falls erforderlich die Repository-Historie separat bereinigen
5. danach Secret-Scanning in CI ergänzen

In einer bereits veröffentlichten Historie vorhandene Werte werden grundsätzlich als kompromittiert behandelt.
