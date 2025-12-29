# Sealed Secrets für Uptime Kuma

Dieses Verzeichnis enthält verschlüsselte Secrets (Sealed Secrets) für Uptime Kuma.

## Vorgehen

1. Erstelle lokal ein Kubernetes Secret mit deinen vertraulichen Werten (z. B. SMTP, Webhooks, Tokens):

```bash
kubectl create secret generic uptime-kuma-secrets -n uptime-kuma \
  --from-literal=SMTP_HOST=smtp.example.com \
  --from-literal=SMTP_PORT=587 \
  --from-literal=SMTP_USERNAME=mailer \
  --from-literal=SMTP_PASSWORD='REPLACE_ME' \
  --dry-run=client -o yaml > /tmp/uptime-kuma-secrets.unsealed.yaml
```

2. Versiegle das Secret mit dem Sealed Secrets Controller:

```bash
kubeseal -f /tmp/uptime-kuma-secrets.unsealed.yaml -o yaml \
  > infrastructure/uptime-kuma/secrets/sealed-uptime-kuma-secrets.yaml
```

3. Committe das versiegelte Secret und apply es:

```bash
git add infrastructure/uptime-kuma/secrets/sealed-uptime-kuma-secrets.yaml
git commit -m "feat(uptime-kuma): add sealed secrets"
kubectl apply -f infrastructure/uptime-kuma/secrets/sealed-uptime-kuma-secrets.yaml
```

Hinweis:

- Das Deployment lädt automatisch alle Schlüssel aus `uptime-kuma-secrets` via `envFrom`.
- Rohdaten (`*.unsealed.yaml`, `.env`) sind in der `.gitignore` bereits ausgeschlossen.
