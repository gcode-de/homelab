# Common Sealed Secrets

Dieses Verzeichnis dient der zentralen Verwaltung verschlüsselter Secrets (Sealed Secrets) für alle Apps.

Empfehlungen:

- Sealed Secrets (verschlüsselte YAMLs) werden committed.
- Unverschlüsselte, temporäre Secret-Dateien werden NICHT committed.

## Unversiegelte Secrets erstellen

```bash
# Beispiel: generiere ein Secret YAML lokal (nicht committen!)
kubectl create secret generic my-secret \
  -n default \
  --from-literal=key=value \
  --dry-run=client -o yaml > /tmp/my-secret.unsealed.yaml

# Mit dem Cluster-öffentlichen Schlüssel versiegeln
kubeseal -f /tmp/my-secret.unsealed.yaml -o yaml \
  > infrastructure/common/secrets/sealed-my-secret.yaml

# Commit & deploy
git add infrastructure/common/secrets/sealed-my-secret.yaml
git commit -m "feat: add sealed secret my-secret"
git push
kubectl apply -f infrastructure/common/secrets/sealed-my-secret.yaml
```

## .gitignore-Empfehlungen

Folgende Dateien sollten ignoriert werden:

- `**/*.unsealed.yaml` (lokale, unverschlüsselte Secret-Dumps)
- `**/*.env` (lokale Env-Dateien)
- `**/tmp/` (temporäre Ordner)

Sealed Secrets (z. B. `sealed-*.yaml`) SOLLEN committed werden.
