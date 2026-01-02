# Calibre-Web Deployment

Calibre-Web ist ein web-basiertes eBook-Management-System mit Zugriff auf deine Bibliothek auf der NAS.

## Features

- ✅ Web-Interface für eBook-Verwaltung
- ✅ Direkte Integration mit NAS-Bibliothek (`/volume1/Privat/WISSEN`)
- ✅ EPUB, PDF, MOBI und weitere Formate
- ✅ Lesegerät im Browser
- ✅ Metadata-Verwaltung
- ✅ Benutzer-Management (optional)

## Voraussetzungen

### NFS-Freigabe auf der Synology NAS

Stelle sicher, dass `/volume1/Privat/WISSEN` über NFS freigegeben ist:

```bash
# SSH zur NAS
ssh admin@192.168.68.126

# NFS-Exports bearbeiten
sudo vi /etc/exports

# Füge hinzu (falls nicht bereits vorhanden):
/volume1/Privat/WISSEN 192.168.68.0/24(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# NFS neu laden
sudo synoservicectl --reload nfsd

# Verifizieren
showmount -e localhost | grep WISSEN
```

### Ordnerstruktur auf der NAS

Calibre-Web erkennt automatisch Unterordner als "Shelves":

```
/volume1/Privat/WISSEN/
├── Sachbücher/
├── Science Fiction/
├── Fantasy/
├── Technische Bücher/
├── Deutsche Literatur/
└── ... weitere Kategorien ...
```

**Wichtig:** Jeder Unterordner sollte eine `metadata.opf` oder ähnliche Struktur haben (standard Calibre-Format).

Wenn deine Bücher nicht in Calibre-Format vorliegen, können sie trotzdem gelesen werden, aber Metadaten müssen manuell hinzugefügt werden.

## Deployment

### 1. NFS-Freigabe aktivieren (siehe oben)

### 2. Deployment starten

```bash
# ArgoCD Application erstellen
kubectl apply -f apps/production/calibre.yaml

# Oder manuell:
kubectl apply -f infrastructure/calibre/namespace.yaml
kubectl apply -f infrastructure/calibre/nfs-volumes.yaml
kubectl apply -f infrastructure/calibre/deployment.yaml
kubectl apply -f infrastructure/calibre/ingress.yaml
kubectl apply -f infrastructure/calibre/ingress-local.yaml

# Status prüfen
kubectl get pods -n calibre
kubectl get svc -n calibre
```

### 3. Zugriff

- **Lokal:** https://calibre.homelab.local
- **Extern:** https://calibre.lab.samuelgesang.de (via Cloudflare Tunnel)

**Erste Anmeldung:**

- Username: `admin`
- Password: `admin123` (ändern nach dem Login!)

## Konfiguration

### Benutzer hinzufügen

Im Web-Interface: Settings → Users → Add new user

### eBooks hinzufügen

**Option 1: Via Web-Interface**

1. Upload-Button im Browser
2. PDF/EPUB hochladen
3. Metadaten eingeben

**Option 2: Direkt auf NAS**

1. SSH zur NAS
2. eBooks in `/volume1/Privat/WISSEN/<Kategorie>/` kopieren
3. Reload in Calibre-Web

### Lesegerät aktivieren

Die meisten eBooks können direkt im Browser gelesen werden:

1. Buch öffnen
2. "Read in Browser" klicken

## Troubleshooting

### NFS-Mount schlägt fehl

```bash
# Prüfe NFS-Connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Im Pod:
# apk add nfs-utils
# showmount -e 192.168.68.126
```

### Keine Bücher sichtbar

```bash
# Prüfe ob Ordner gemountet ist
kubectl exec -it -n calibre deploy/calibre-web -- ls -la /books

# Prüfe Berechtigungen
kubectl exec -it -n calibre deploy/calibre-web -- stat /books
```

### Admin-Passwort zurücksetzen

```bash
# In die Datenbank schauen
kubectl exec -it -n calibre deploy/calibre-web -- sh

# Dann im Container Datenbankpfad: /config/app.db
```

## Integration mit Paperless-NGX

Falls du die eBooks automatisch aus Paperless exportieren möchtest, können diese in `/volume1/Privat/WISSEN/` sortiert werden.

## Weitere Optionen

### Kaliber-Content-Server (optional)

Für erweiterte Features kann ein separater Calibre Content-Server installiert werden:

```bash
# Calibre-Server starten (optional in Zukunft)
docker run -d calibre-server /volume1/Privat/WISSEN
```

### Sync mit E-Reader

Calibre-Web kann Geräte verwalten (Kindle, Kobo, etc.) - konfigurierbar über Einstellungen.
