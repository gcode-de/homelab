# Paperless-NGX Deployment Anleitung

## Voraussetzungen

### 1. NFS-Freigaben auf der Synology NAS (192.168.68.126) erstellen

**Variante A: Über DSM Web-UI**

1. DSM → Systemsteuerung → Dateidienste → NFS aktivieren (NFSv3 oder NFSv4.1; v4.1 kann je nach Pseudo-Root-Konfig scheitern)
2. Systemsteuerung → Gemeinsamer Ordner:

- Wähle `/volume1/scans` → Bearbeiten → NFS-Berechtigung
  - Erstellen: Server/IP: `192.168.68.0/24`, Berechtigung: Lesen/Schreiben
- Wähle `/volume1/Privat/DATA` → Bearbeiten → NFS-Berechtigung
  - Erstellen: Server/IP: `192.168.68.0/24`, Berechtigung: Lesen/Schreiben

**Variante B: Über SSH (schneller)**

```bash
# SSH zur NAS
ssh admin@192.168.68.126

# NFS-Exports bearbeiten
sudo vi /etc/exports

# Füge hinzu:
/volume1/scans 192.168.68.0/24(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)
/volume1/Privat/DATA 192.168.68.0/24(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)

# NFS neu laden
sudo synoservicectl --reload nfsd
```

### 2. NFS-Test vom Kubernetes-Node

```bash
# Teste NFS-Mount
showmount -e 192.168.68.126

# Sollte anzeigen:
# /volume1/scans       192.168.68.0/24
# /volume1/Privat/DATA 192.168.68.0/24

# Optional: Test-Mount (falls NFSv4.1 fehlschlägt, nfsvers=3 nutzen)
sudo mount -t nfs -o nfsvers=3 192.168.68.126:/volume1/scans /mnt
ls /mnt
sudo umount /mnt
```

## Deployment-Schritte

### 1. Secrets erstellen

Folge den Anweisungen in `infrastructure/paperless-ngx/secrets/README.md`

### 2. Anpassen der Ordner-Mappings

**Das neue Post-Consume Script scannt automatisch deine Ordnerstruktur!**

Es erstellt einen Cache der vorhandenen Ordner (bis Ebene 3) und matched intelligent basierend auf:

- **Tags** (z.B. Tag "Versicherung" → Ordner "Versicherungen")
- **Correspondents** (z.B. Correspondent "Allianz" → Ordner mit "Allianz" im Namen)
- **Keywords** (Erkennt automatisch Finanzen, Steuern, Gesundheit, etc.)

**Scoring-System:**

- Tag-Match: +10 Punkte
- Correspondent-Match: +15 Punkte
- Keyword-Match: +5 Punkte
- Mindest-Score für Auto-Sortierung: 5 Punkte

**Wenn kein Match:** Dokument landet in `/volume1/Privat/DATA/Unsortiert`

Du musst also **keine manuelle Konfiguration** vornehmen! Lege einfach deine Ordner an und das Script findet sie automatisch.

**Optional: Ordnerstruktur vorab prüfen:**

```bash
# Zeige aktuelle Ordnerstruktur
ssh admin@192.168.68.126 "find /volume1/Privat/DATA -maxdepth 3 -type d"

# Das Script cached diese Struktur automatisch (Cache: 1 Stunde)
```

### 3. Post-Consume Script als ConfigMap erstellen

```bash
kubectl create configmap paperless-post-consume-script -n paperless-ngx \
  --from-file=post-consume.sh=infrastructure/paperless-ngx/post-consume-script.sh
```

### 4. Optional: NFS-Konfiguration anpassen

Falls du eine andere NAS-IP oder Pfade nutzt, bearbeite:
`infrastructure/paperless-ngx/nfs-config.yaml` (oder direkt in `nfs-volumes.yaml`)

**Sicherheitshinweis:** Die NFS-IP (192.168.68.126) ist eine private RFC1918-Adresse und auf GitHub unkritisch. Falls du sie trotzdem privat halten möchtest:

```bash
# Füge zur .gitignore hinzu:
echo "infrastructure/paperless-ngx/nfs-config.yaml" >> .gitignore
```

### 6. Zugriff

- **Lokal:** https://paperless.homelab.local
- **Extern:** https://paperless.lab.samuelgesang.de (via Cloudflare Tunnel)

Login mit den Credentials aus dem Secret (siehe `secrets/README.md`)

## Post-Consume Script aktivieren

Um das automatische Sortieren zu aktivieren:

```bash
# Füge zum Deployment hinzu (in deployment.yaml):
env:
  - name: PAPERLESS_POST_CONSUME_SCRIPT
    value: /scripts/post-consume.sh

volumeMounts:
  - name: post-consume-script
    mountPath: /scripts

volumes:
  - name: post-consume-script
    configMap:
      name: paperless-post-consume-script
      defaultMode: 0755
```

## Workflow

1. **PDF in `/volume1/scans` legen** (z.B. über Scanner)
2. **Paperless erkennt neue Datei** (Polling alle 60 Sekunden)
3. **OCR & Import** → Dokument wird analysiert
4. **Auto-Tagging** → ML erkennt Typ/Correspondent
5. **Intelligentes Matching:**
   - Script scannt vorhandene Ordnerstruktur (bis 5 Ebenen)
   - Matched Tags/Correspondent/Keywords mit Ordnernamen
   - Scoring-System bestimmt besten Match
6. **Intelligentes Renaming** → Dateiname wird mit Datum, Correspondent und Tag aufgebessert
7. **Post-Consume Script** → Kopiert mit neuem Namen in `/volume1/Privat/DATA/<beste-match>`
8. **Original in `/volume1/scans` bleibt** (oder wird gelöscht wenn `PAPERLESS_CONSUMER_DELETE_DUPLICATES=true`)

**Beispiel Umbenennungen:**

```
Original:     "scan_001.pdf"
Datum:        2025-12-30
Correspondent: Allianz
Tag:          Versicherung

→ Neuer Name: "2025-12-30_Allianz_Versicherung.pdf"

Nur mit Correspondent:
→ "2025-12-30_Allianz.pdf"

Nur mit Tag:
→ "2025-12-30_Versicherung.pdf"
```

**Duplikat-Handling:**
Falls die Datei bereits existiert, wird eine Nummer angehängt:

- `2025-12-30_Allianz_Versicherung.pdf`
- `2025-12-30_Allianz_Versicherung_1.pdf`
- `2025-12-30_Allianz_Versicherung_2.pdf`

## Weitere Konfiguration

### Eigene Ordnerstruktur nutzen

Das Post-Consume Script ist **bereits auf deine konkrete Ordnerstruktur abgestimmt**!

Siehe **[ORDNERSTRUKTUR.md](ORDNERSTRUKTUR.md)** für Details zu allen Mappings.

**Vorkonfiguriert für:**

- ✅ Auto
- ✅ Finanz (mit allen Unterkategorien)
  - Altersvorsorge, BAföG, Halbwaisenrente, Kindergarten, Kindergeld, Steuerbescheide
- ✅ Finanz/Versicherungen (mit allen Typen)
  - KFZ, Krankenversicherung, Berufsunfähigkeit, Hausrat, Haftpflicht, Rechtschutz, Auslands-KV, Risiko-Leben
- ✅ Personen-Ordner (Elisabeth, Johanna, Samuel, Victoria)
- ✅ Wohnung
- ✅ Familie

Das Script erkennt automatisch:

- Deutsche Begriffe und Synonyme
- Versicherungsgesellschaften (Allianz, TK, Barmer, etc.)
- Personen-Namen (höchste Priorität)
- Kontextuelle Keywords

### Intelligente Datei-Umbenennung

Das Post-Consume Script benennt Dateien automatisch um:

**Naming-Format:**

```
YYYY-MM-DD_[Correspondent]_[Tag].pdf
```

**Intelligente Fallback-Logik:**

1. Wenn Tag + Correspondent vorhanden: `2025-12-30_Allianz_Versicherung.pdf`
2. Wenn nur Correspondent: `2025-12-30_Allianz.pdf`
3. Wenn nur Tag: `2025-12-30_Versicherung.pdf`
4. Fallback: `2025-12-30_original_filename.pdf`

**Features:**

- ✅ Sonderzeichen werden in Underscores konvertiert
- ✅ Datum aus Dokumenten-Metadaten
- ✅ Erste Tag wird als Klassifizierung genutzt
- ✅ Automatische Duplikat-Behandlung (anhängende Nummern)
- ✅ Max 200 Zeichen (Dateisystem-Kompatibilität)

### Naming anpassen

Die Datei-Umbenennung erfolgt in der `generate_smart_filename()` Funktion. Du kannst:

- Format ändern (aktuell: `YYYY-MM-DD_Correspondent_Tag`)
- Andere Metadaten nutzen (z.B. Document ID, Type)
- Datum-Format ändern (aktuell: ISO 8601)

### Machine Learning Training

Nach ~100 Dokumenten trainiert Paperless automatisch:

- Document Type Classification
- Correspondent Matching
- Auto-Tagging

## Troubleshooting

### NFS-Mount schlägt fehl

```bash
# Prüfe NFS-Connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Im Pod:
# apk add nfs-utils
# showmount -e 192.168.68.126
```

### Consume funktioniert nicht

```bash
# Prüfe Berechtigungen
kubectl exec -it -n paperless-ngx deploy/paperless-ngx -- ls -la /usr/src/paperless/consume

# Prüfe Logs
kubectl logs -n paperless-ngx -l app=paperless-ngx | grep -i consume
```

### Post-Consume Script läuft nicht

```bash
# Prüfe ob Script mountet ist
kubectl exec -it -n paperless-ngx deploy/paperless-ngx -- cat /scripts/post-consume.sh

# Prüfe Logs
kubectl exec -it -n paperless-ngx deploy/paperless-ngx -- tail -f /tmp/paperless-sort.log
```
