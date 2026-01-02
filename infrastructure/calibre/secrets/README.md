# Calibre-Web Secrets

Calibre-Web benötigt keine Secrets (keine Datenbankverbindung wie Paperless).

Optional kannst du folgendes setzen:

## Umgebungsvariablen (optional)

Falls gewünscht, können diese über eine ConfigMap gesetzt werden:

```bash
kubectl create configmap calibre-config -n calibre \
  --from-literal=CALIBRE_WEB_TITLE="Meine eBook-Bibliothek" \
  --from-literal=CALIBRE_WEB_COLUMNS="title,authors,series,rating" \
  --from-literal=CALIBRE_GUEST_ACCESS="true"
```

## Admin-Zugang

Nach der Installation:

- Gehe zu: https://calibre.homelab.local
- Login: `admin` / `admin123`
- Gehe zu Settings → Admin
- Ändere das Passwort!

## Benutzer-Management

Nach dem Login können weitere Benutzer erstellt werden:

- Settings → Users → Add User
- Optional: Gast-Zugang aktivieren (Settings → Web Interface)
