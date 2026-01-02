# Paperless-NGX: Ordnerstruktur-Mapping

## Deine aktuelle Ordnerstruktur

Diese Datei dokumentiert, wie das Post-Consume Script deine spezifische Ordnerstruktur erkennt und zuordnet.

## Mapping-Beispiele

### Auto

**Ordner:** `/volume1/Privat/DATA/Auto`

**Erkannte Keywords:**

- auto, kfz, fahrzeug
- versicherung + kfz
- zulassung, tüv, werkstatt

**Beispiele:**

- Tag "KFZ" + Correspondent "TÜV Süd" → `Auto/`
- Tag "Versicherung" + "KFZ" im Text → `Auto/` oder `Finanz/Versicherungen/KFZ`

---

### Finanz - Altersvorsorge

**Ordner:** `/volume1/Privat/DATA/Finanz/Altersvorsorge`

**Erkannte Keywords:**

- rente, altersvorsorge, riester, rürup
- pension, vorsorge

**Beispiele:**

- Correspondent "DWS Riester" → `Finanz/Altersvorsorge/`
- Tag "Rente" → `Finanz/Altersvorsorge/`

---

### Finanz - BAföG

**Ordner:** `/volume1/Privat/DATA/Finanz/BAföG Johanna`

**Erkannte Keywords:**

- bafög, bafoeg
- ausbildungsförderung, studienfinanzierung

**Beispiele:**

- Correspondent "Studentenwerk" + Tag "BAföG" → `Finanz/BAföG Johanna/`
- Tag "Johanna" + "BAföG" → `Finanz/BAföG Johanna/`

---

### Finanz - Kindergeld

**Ordner:** `/volume1/Privat/DATA/Finanz/Kindergeld`

**Erkannte Keywords:**

- kindergeld, familienkasse

**Beispiele:**

- Correspondent "Familienkasse" → `Finanz/Kindergeld/`

---

### Finanz - Steuerbescheide

**Ordner:** `/volume1/Privat/DATA/Finanz/Steuerbescheide`

**Erkannte Keywords:**

- steuer, finanzamt, steuererklärung
- einkommensteuer, bescheid

**Beispiele:**

- Correspondent "Finanzamt München" → `Finanz/Steuerbescheide/`
- Tag "Steuerbescheid" → `Finanz/Steuerbescheide/`

---

### Finanz - Versicherungen - KFZ

**Ordner:** `/volume1/Privat/DATA/Finanz/Versicherungen/KFZ`

**Erkannte Keywords:**

- kfz + versicherung
- autoversicherung, kasko

**Beispiele:**

- Correspondent "Allianz" + Tag "KFZ" → `Finanz/Versicherungen/KFZ/`
- Tag "Autoversicherung" → `Finanz/Versicherungen/KFZ/`

---

### Finanz - Versicherungen - Krankenversicherung

**Ordner:** `/volume1/Privat/DATA/Finanz/Versicherungen/Krankenversicherung`

**Erkannte Keywords:**

- krankenversicherung, krankenkasse
- gesundheit, tk, barmer, aok

**Beispiele:**

- Correspondent "TK" → `Finanz/Versicherungen/Krankenversicherung/`
- Tag "Krankenkasse" → `Finanz/Versicherungen/Krankenversicherung/`

---

### Finanz - Versicherungen - Berufsunfähigkeit

**Ordner:** `/volume1/Privat/DATA/Finanz/Versicherungen/Berufsunfähigkeit`

**Erkannte Keywords:**

- berufsunfähigkeit, bu versicherung
- erwerbsunfähigkeit

**Beispiele:**

- Correspondent "Allianz" + Tag "BU" → `Finanz/Versicherungen/Berufsunfähigkeit/`

---

### Finanz - Versicherungen - Hausrat

**Ordner:** `/volume1/Privat/DATA/Finanz/Versicherungen/Hausrat`

**Erkannte Keywords:**

- hausrat, hausratversicherung

**Beispiele:**

- Tag "Hausrat" → `Finanz/Versicherungen/Hausrat/`

---

### Finanz - Versicherungen - Privat Haftpflicht

**Ordner:** `/volume1/Privat/DATA/Finanz/Versicherungen/Privat Haftpflicht`

**Erkannte Keywords:**

- haftpflicht, privathaftpflicht
- privat + haftpflicht

**Beispiele:**

- Tag "Haftpflicht" → `Finanz/Versicherungen/Privat Haftpflicht/`

---

### Finanz - Versicherungen - Rechtschutz

**Ordner:** `/volume1/Privat/DATA/Finanz/Versicherungen/Rechtschutz`

**Erkannte Keywords:**

- rechtschutz, rechtsschutzversicherung

**Beispiele:**

- Tag "Rechtschutz" → `Finanz/Versicherungen/Rechtschutz/`

---

### Finanz - Versicherungen - Auslands-KV

**Ordner:** `/volume1/Privat/DATA/Finanz/Versicherungen/Auslands-KV`

**Erkannte Keywords:**

- ausland + kranken
- reisekranken, reiseversicherung

**Beispiele:**

- Tag "Auslandskrankenversicherung" → `Finanz/Versicherungen/Auslands-KV/`

---

### Personen-Ordner

**Ordner:** `/volume1/Privat/DATA/[Name]`

- Elisabeth
- Johanna
- Samuel
- Victoria

**Erkannte Keywords:**

- Name im Tag oder Correspondent

**Beispiele:**

- Tag "Johanna" + "Zeugnis" → `Johanna/`
- Correspondent "Schule" + Tag "Samuel" → `Samuel/`

**Scoring:**

- Personen-Match hat höchste Priorität (Score: 20)

---

### Wohnung

**Ordner:** `/volume1/Privat/DATA/Wohnung`

**Erkannte Keywords:**

- wohnung, miete, nebenkosten
- betriebskosten, heizung, strom
- vermieter

**Beispiele:**

- Tag "Miete" → `Wohnung/`
- Correspondent "Stadtwerke" + Tag "Strom" → `Wohnung/`

---

### Familie

**Ordner:** `/volume1/Privat/DATA/Familie allg` oder `/erweiterte Familie`

**Erkannte Keywords:**

- familie, verwandtschaft
- geburt, heirat, familienfest

**Beispiele:**

- Tag "Familie" → `Familie allg/`

---

## Scoring-System

**Prioritäten (höchste zuerst):**

1. **Personen-Namen** (Score: 20) - Elisabeth, Johanna, Samuel, Victoria
2. **Correspondent-Match** (Score: 15) - Exact match im Ordnernamen
3. **Spezifische Keywords** (Score: 8-15) - BAföG, Kindergeld, Versicherungstyp
4. **Tags** (Score: 10) - Tag-Name matched Ordner
5. **Allgemeine Keywords** (Score: 5-8) - Finanz, Wohnung, Auto

**Mindest-Score für Auto-Sortierung:** 5 Punkte

**Fallback:** Wenn kein Match → `/volume1/Privat/DATA/Unsortiert`

## Anpassungen vornehmen

Falls das Matching nicht perfekt ist, kannst du in `post-consume-script.sh` anpassen:

1. **Keyword hinzufügen:**

   ```bash
   if [[ "$combined" =~ (neues_keyword|synonym) ]]; then
       if [[ "$folder_lower" =~ ordnername ]]; then
           score=$((score + 10))
       fi
   fi
   ```

2. **Scoring anpassen:**

   - Erhöhe Score für wichtigere Matches
   - Senke Score für zu breite Matches

3. **Mindest-Score ändern:**
   ```bash
   if [ $best_score -ge 5 ]; then  # Auf 8 erhöhen für strikteres Matching
   ```

## Beispiel-Workflows

### Workflow 1: Versicherungspolice

```
Input:  scan_2025_001.pdf
OCR:    "Allianz Versicherungs-AG, Berufsunfähigkeitsversicherung, Police Nr. 12345"

→ Auto-Tag: "Versicherung", "BU"
→ Correspondent: "Allianz"

Matching:
- Tag "BU" matched "Berufsunfähigkeit" → +12
- Correspondent "Allianz" in Ordner → +15
- Keyword "berufsunfähigkeit" → +12
→ Total Score: 39

Output: /volume1/Privat/DATA/Finanz/Versicherungen/Berufsunfähigkeit/2025-12-30_Allianz_BU.pdf
```

### Workflow 2: Kindergeld-Bescheid

```
Input:  IMG_4532.pdf
OCR:    "Familienkasse Bayern Süd, Kindergeldbescheid für Johanna"

→ Auto-Tag: "Kindergeld", "Johanna"
→ Correspondent: "Familienkasse"

Matching:
- Tag "Johanna" matched Personen-Ordner → +20
- Tag "Kindergeld" → +15
- Keyword "kindergeld" → +15
→ Kindergeld-Ordner gewinnt (höherer Kontext-Score)

Output: /volume1/Privat/DATA/Finanz/Kindergeld/2025-12-30_Familienkasse_Kindergeld.pdf
```

### Workflow 3: Mietrechnung

```
Input:  rechnung_wohnung.pdf
OCR:    "Stadtwerke München, Nebenkostenabrechnung"

→ Auto-Tag: "Rechnung", "Nebenkosten"
→ Correspondent: "Stadtwerke"

Matching:
- Keyword "nebenkosten" matched "Wohnung" → +10
- Tag "Rechnung" matched "Finanz" → +5
→ Wohnung gewinnt

Output: /volume1/Privat/DATA/Wohnung/2025-12-30_Stadtwerke_Rechnung.pdf
```

## Log-Überprüfung

Alle Sortier-Entscheidungen werden geloggt:

```bash
# Logs im Container prüfen
kubectl exec -it -n paperless-ngx deploy/paperless-ngx -- tail -f /tmp/paperless-sort.log

# Beispiel-Output:
# 2026-01-01 10:30:15: Document 42 | Renamed: 'scan_001.pdf' → '2025-12-30_Allianz_BU.pdf' |
#   Sorted to 'Finanz/Versicherungen/Berufsunfähigkeit' | Tags: Versicherung, BU | Correspondent: Allianz
```
