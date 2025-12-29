# Sealed Secrets für Netbox

Diese Secrets sind mit Sealed Secrets verschlüsselt und können sicher ins Git committed werden.

## Neues Secret erstellen

1. Erstelle ein normales Kubernetes Secret:

```bash
kubectl create secret generic my-secret -n netbox \
  --from-literal=key=value \
  --dry-run=client -o yaml > /tmp/my-secret.yaml
```

2. Verschlüssele es mit kubeseal:

```bash
kubeseal -f /tmp/my-secret.yaml -o yaml > infrastructure/netbox/secrets/sealed-my-secret.yaml
```

3. Committe das Sealed Secret ins Git:

```bash
git add infrastructure/netbox/secrets/sealed-my-secret.yaml
git commit -m "feat: add sealed secret my-secret"
git push
```

4. Deploye es:

```bash
kubectl apply -f infrastructure/netbox/secrets/sealed-my-secret.yaml
```

Der Sealed Secrets Controller entschlüsselt es automatisch im Cluster.

## Bestehendes Secret aktualisieren

1. Hole das aktuelle Secret:

```bash
kubectl get secret netbox-db-credentials -n netbox -o yaml > /tmp/secret.yaml
```

2. Bearbeite die Werte in `/tmp/secret.yaml`

3. Verschlüssele neu:

```bash
kubeseal -f /tmp/secret.yaml -o yaml > infrastructure/netbox/secrets/sealed-db-credentials.yaml
```

4. Committe und deploye wie oben

## Secrets in diesem Verzeichnis

- `sealed-db-credentials.yaml` - PostgreSQL Datenbank-Passwort
- `sealed-netbox-secrets.yaml` - Netbox SECRET_KEY

**Wichtig**: Diese Dateien sind verschlüsselt und nur der Cluster kann sie entschlüsseln!
