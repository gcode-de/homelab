# Paperless-NGX Secrets erstellen

## 1. Erstelle unsealed Secrets (NICHT committen!)

```bash
# Generiere zufällige Secrets
POSTGRES_USER="paperless"
POSTGRES_PASSWORD=$(openssl rand -base64 32)
SECRET_KEY=$(openssl rand -base64 50)
ADMIN_USER="admin"
ADMIN_PASSWORD=$(openssl rand -base64 16)

# Erstelle Secret YAML
cat > paperless-secrets.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: paperless-secrets
  namespace: paperless-ngx
type: Opaque
stringData:
  postgres-user: $POSTGRES_USER
  postgres-password: $POSTGRES_PASSWORD
  secret-key: $SECRET_KEY
  admin-user: $ADMIN_USER
  admin-password: $ADMIN_PASSWORD
EOF

# Zeige Admin-Credentials
echo ""
echo "=== Paperless-NGX Admin Credentials ==="
echo "Username: $ADMIN_USER"
echo "Password: $ADMIN_PASSWORD"
echo "========================================"
echo ""
echo "WICHTIG: Speichere diese Credentials sicher!"
```

## 2. Erstelle SealedSecret

```bash
# Seal das Secret
kubeseal --format=yaml --cert=../common/secrets/sealed-secrets-pub.pem \
  < paperless-secrets.yaml \
  > sealed-paperless-secrets.yaml

# Lösche unsealed Secret
rm paperless-secrets.yaml

# Committe SealedSecret
git add sealed-paperless-secrets.yaml
git commit -m "feat(paperless): add sealed secrets"
```

## 3. Alternative: Manuelles Secret erstellen

Falls du das Secret lieber manuell erstellst:

```bash
kubectl create secret generic paperless-secrets -n paperless-ngx \
  --from-literal=postgres-user=paperless \
  --from-literal=postgres-password=DEIN_POSTGRES_PASSWORD \
  --from-literal=secret-key=DEIN_SECRET_KEY \
  --from-literal=admin-user=admin \
  --from-literal=admin-password=DEIN_ADMIN_PASSWORD
```
