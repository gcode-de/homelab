#!/bin/bash
# Post-Consume Script für automatisches Sortieren in Unterordner
# Scannt automatisch vorhandene Ordnerstruktur und matched intelligent

DOCUMENT_ID="$1"
DOCUMENT_FILE_NAME="$2"
DOCUMENT_CREATED="$3"
DOCUMENT_MODIFIED="$4"
DOCUMENT_ADDED="$5"
DOCUMENT_SOURCE_PATH="$6"
DOCUMENT_ARCHIVE_PATH="$7"
DOCUMENT_THUMBNAIL_PATH="$8"
DOCUMENT_DOWNLOAD_URL="$9"
DOCUMENT_CORRESPONDENT="${10}"
DOCUMENT_TAGS="${11}"

# Export-Basis-Pfad
EXPORT_BASE="/usr/src/paperless/export"

# Cache für Ordnerstruktur (wird beim ersten Lauf erstellt)
FOLDER_CACHE="/tmp/paperless-folders.cache"
FOLDER_CACHE_AGE=3600  # 1 Stunde

# Standard-Ordner wenn kein Match
DEFAULT_FOLDER="Unsortiert"

# Funktion: Scanne Ordnerstruktur (bis Ebene 5)
scan_folder_structure() {
    echo "Scanning folder structure..." >> /tmp/paperless-sort.log
    find "$EXPORT_BASE" -maxdepth 5 -type d -not -path "$EXPORT_BASE/$DEFAULT_FOLDER*" | \
        sed "s|$EXPORT_BASE/||" | \
        grep -v "^$" > "$FOLDER_CACHE"
}

# Funktion: Aktualisiere Cache falls älter als FOLDER_CACHE_AGE
update_cache_if_needed() {
    if [ ! -f "$FOLDER_CACHE" ] || [ $(find "$FOLDER_CACHE" -mmin +$((FOLDER_CACHE_AGE/60)) 2>/dev/null | wc -l) -gt 0 ]; then
        scan_folder_structure
    fi
}

# Funktion: Finde besten Match basierend auf Tags, Correspondent und Ordnernamen
find_best_match() {
    local tags="$1"
    local correspondent="$2"
    local best_match=""
    local best_score=0
    
    # Lese gecachte Ordner
    while IFS= read -r folder; do
        local score=0
        local folder_lower=$(echo "$folder" | tr '[:upper:]' '[:lower:]')
        
        # Scoring: Tags
        IFS=',' read -ra TAG_ARRAY <<< "$tags"
        for tag in "${TAG_ARRAY[@]}"; do
            tag=$(echo "$tag" | tr '[:upper:]' '[:lower:]' | xargs)
            if [[ "$folder_lower" == *"$tag"* ]]; then
                score=$((score + 10))
            fi
        done
        
        # Scoring: Correspondent
        if [ -n "$correspondent" ]; then
            correspondent_lower=$(echo "$correspondent" | tr '[:upper:]' '[:lower:]')
            if [[ "$folder_lower" == *"$correspondent_lower"* ]]; then
                score=$((score + 15))
            fi
        fi
        
        # Scoring: Keyword-Matching (basierend auf deiner Ordnerstruktur)
        local combined="${tags,,} ${correspondent,,}"  # lowercase
        
        # Auto
        if [[ "$combined" =~ (auto|kfz|fahrzeug|versicherung.*kfz|zulassung|tüv|werkstatt) ]]; then
            if [[ "$folder_lower" =~ (auto|kfz|fahrzeug) ]]; then
                score=$((score + 8))
            fi
        fi
        
        # Finanz - Allgemein
        if [[ "$combined" =~ (bank|konto|iban|überweisung|finanz|geld|depot|sparkasse|volksbank) ]]; then
            if [[ "$folder_lower" =~ finanz ]]; then
                score=$((score + 5))
            fi
        fi
        
        # Finanz - Altersvorsorge
        if [[ "$combined" =~ (rente|altersvorsorge|riester|rürup|pension|vorsorge) ]]; then
            if [[ "$folder_lower" =~ (altersvorsorge|vorsorge|rente) ]]; then
                score=$((score + 10))
            fi
        fi
        
        # Finanz - BAföG
        if [[ "$combined" =~ (bafög|bafoeg|ausbildungsförderung|studienfinanzierung) ]]; then
            if [[ "$folder_lower" =~ (bafög|bafoeg) ]]; then
                score=$((score + 15))
            fi
        fi
        
        # Finanz - Halbwaisenrente
        if [[ "$combined" =~ (waisenrente|halbwaise|rentenversicherung) ]]; then
            if [[ "$folder_lower" =~ (waisenrente|halbwaise) ]]; then
                score=$((score + 15))
            fi
        fi
        
        # Finanz - Kindergarten
        if [[ "$combined" =~ (kindergarten|kita|kindertagesstätte|betreuung) ]]; then
            if [[ "$folder_lower" =~ (kindergarten|kita) ]]; then
                score=$((score + 12))
            fi
        fi
        
        # Finanz - Kindergeld
        if [[ "$combined" =~ (kindergeld|familienkasse) ]]; then
            if [[ "$folder_lower" =~ kindergeld ]]; then
                score=$((score + 15))
            fi
        fi
        
        # Finanz - Steuerbescheide
        if [[ "$combined" =~ (steuer|finanzamt|steuererklärung|einkommensteuer|bescheid) ]]; then
            if [[ "$folder_lower" =~ (steuer|finanzamt) ]]; then
                score=$((score + 8))
            fi
        fi
        
        # Versicherungen - KFZ
        if [[ "$combined" =~ (kfz.*versicherung|autoversicherung|kasko) ]]; then
            if [[ "$folder_lower" =~ (versicherungen/kfz|kfz) ]]; then
                score=$((score + 12))
            fi
        fi
        
        # Versicherungen - Krankenversicherung
        if [[ "$combined" =~ (krankenversicherung|krankenkasse|gesundheit|tk|barmer|aok) ]]; then
            if [[ "$folder_lower" =~ (krankenversicherung|krankenkasse) ]]; then
                score=$((score + 10))
            fi
        fi
        
        # Versicherungen - Berufsunfähigkeit
        if [[ "$combined" =~ (berufsunfähigkeit|bu.*versicherung|erwerbsunfähigkeit) ]]; then
            if [[ "$folder_lower" =~ (berufsunfähigkeit|bu) ]]; then
                score=$((score + 12))
            fi
        fi
        
        # Versicherungen - Hausrat
        if [[ "$combined" =~ (hausrat|hausratversicherung) ]]; then
            if [[ "$folder_lower" =~ hausrat ]]; then
                score=$((score + 12))
            fi
        fi
        
        # Versicherungen - Haftpflicht
        if [[ "$combined" =~ (haftpflicht|privathaftpflicht|privat.*haftpflicht) ]]; then
            if [[ "$folder_lower" =~ (haftpflicht|privat.*haftpflicht) ]]; then
                score=$((score + 12))
            fi
        fi
        
        # Versicherungen - Rechtschutz
        if [[ "$combined" =~ (rechtschutz|rechtsschutzversicherung) ]]; then
            if [[ "$folder_lower" =~ rechtschutz ]]; then
                score=$((score + 12))
            fi
        fi
        
        # Versicherungen - Risikolebensversicherung
        if [[ "$combined" =~ (risikoleben|lebensversicherung|todesfallschutz) ]]; then
            if [[ "$folder_lower" =~ (risiko.*leben|lebensversicherung) ]]; then
                score=$((score + 10))
            fi
        fi
        
        # Versicherungen - Auslandskrankenversicherung
        if [[ "$combined" =~ (ausland.*kranken|reisekranken|reiseversicherung) ]]; then
            if [[ "$folder_lower" =~ (auslands.*kv|ausland.*kranken) ]]; then
                score=$((score + 12))
            fi
        fi
        
        # Personen-Ordner
        if [[ "$combined" =~ (elisabeth) ]]; then
            if [[ "$folder_lower" =~ elisabeth ]]; then
                score=$((score + 20))
            fi
        fi
        
        if [[ "$combined" =~ (johanna) ]]; then
            if [[ "$folder_lower" =~ johanna ]]; then
                score=$((score + 20))
            fi
        fi
        
        if [[ "$combined" =~ (samuel) ]]; then
            if [[ "$folder_lower" =~ samuel ]]; then
                score=$((score + 20))
            fi
        fi
        
        if [[ "$combined" =~ (victoria) ]]; then
            if [[ "$folder_lower" =~ victoria ]]; then
                score=$((score + 20))
            fi
        fi
        
        # Wohnung
        if [[ "$combined" =~ (wohnung|miete|nebenkosten|betriebskosten|heizung|strom|vermieter) ]]; then
            if [[ "$folder_lower" =~ wohnung ]]; then
                score=$((score + 10))
            fi
        fi
        
        # Familie
        if [[ "$combined" =~ (familie|verwandtschaft|geburt|heirat|familienfest) ]]; then
            if [[ "$folder_lower" =~ (familie|verwandtschaft) ]]; then
                score=$((score + 8))
            fi
        fi
        
        # Beste Match speichern
        if [ $score -gt $best_score ]; then
            best_score=$score
            best_match="$folder"
        fi
    done < "$FOLDER_CACHE"
    
    # Mindest-Score für Auto-Sortierung
    if [ $best_score -ge 5 ]; then
        echo "$best_match"
    else
        echo "$DEFAULT_FOLDER"
    fi
}

# Update Cache
update_cache_if_needed

# Bestimme Zielordner
TARGET_FOLDER=$(find_best_match "$DOCUMENT_TAGS" "$DOCUMENT_CORRESPONDENT")
TARGET_PATH="$EXPORT_BASE/$TARGET_FOLDER"

# Erstelle Ordner falls nicht existent
mkdir -p "$TARGET_PATH"

# Funktion: Generiere intelligenten Dateinamen
generate_smart_filename() {
    local date="$1"
    local correspondent="$2"
    local tags="$3"
    local filename="$4"
    local extension="${filename##*.}"
    
    # Cleanup: Sonderzeichen entfernen
    correspondent=$(echo "$correspondent" | sed 's/[^a-zA-Z0-9._-]/_/g' | sed 's/_\+/_/g' | sed 's/_$//g')
    
    # Extrahiere erstes sinnvolles Tag (vor Komma)
    first_tag=$(echo "$tags" | cut -d',' -f1 | sed 's/^ *//;s/ *$//' | sed 's/[^a-zA-Z0-9._-]/_/g')
    
    # Formatiere Datum: YYYY-MM-DD
    doc_date=$(echo "$date" | cut -d' ' -f1 || echo "$(date +%Y-%m-%d)")
    
    # Generiere Namen basierend auf verfügbaren Infos
    local new_name=""
    
    if [ -n "$correspondent" ] && [ -n "$first_tag" ]; then
        # Format: YYYY-MM-DD_Correspondent_Tag.pdf
        new_name="${doc_date}_${correspondent}_${first_tag}.${extension}"
    elif [ -n "$correspondent" ]; then
        # Format: YYYY-MM-DD_Correspondent.pdf
        new_name="${doc_date}_${correspondent}.${extension}"
    elif [ -n "$first_tag" ]; then
        # Format: YYYY-MM-DD_Tag.pdf
        new_name="${doc_date}_${first_tag}.${extension}"
    else
        # Fallback: Original-Name mit Datum präfixed
        new_name="${doc_date}_${filename}"
    fi
    
    # Kürze auf max 200 Zeichen (Dateisystem-Limit)
    if [ ${#new_name} -gt 200 ]; then
        new_name="${new_name:0:150}.${extension}"
    fi
    
    echo "$new_name"
}

# Funktion: Prüfe ob Datei bereits existiert und füge Nummer hinzu wenn nötig
get_unique_filename() {
    local target_dir="$1"
    local filename="$2"
    local base="${filename%.*}"
    local extension="${filename##*.}"
    local counter=1
    local new_name="$filename"
    
    while [ -f "$target_dir/$new_name" ]; do
        new_name="${base}_${counter}.${extension}"
        counter=$((counter + 1))
    done
    
    echo "$new_name"
}

# Bestimme Quelldatei
if [ -f "$DOCUMENT_ARCHIVE_PATH" ]; then
    SOURCE_FILE="$DOCUMENT_ARCHIVE_PATH"
else
    SOURCE_FILE="$DOCUMENT_SOURCE_PATH"
fi

# Generiere intelligenten Dateinamen
SMART_FILENAME=$(generate_smart_filename "$DOCUMENT_CREATED" "$DOCUMENT_CORRESPONDENT" "$DOCUMENT_TAGS" "$DOCUMENT_FILE_NAME")

# Prüfe auf Duplikate
FINAL_FILENAME=$(get_unique_filename "$TARGET_PATH" "$SMART_FILENAME")

# Kopiere/Verschiebe Dokument mit neuem Namen
if [ -f "$SOURCE_FILE" ]; then
    cp "$SOURCE_FILE" "$TARGET_PATH/$FINAL_FILENAME"
    
    # Log für Debugging
    echo "$(date): Document $DOCUMENT_ID | Renamed: '$DOCUMENT_FILE_NAME' → '$FINAL_FILENAME' | Sorted to '$TARGET_FOLDER' | Tags: $DOCUMENT_TAGS | Correspondent: $DOCUMENT_CORRESPONDENT" >> /tmp/paperless-sort.log
else
    echo "$(date): ERROR - Source file not found for document $DOCUMENT_ID" >> /tmp/paperless-sort.log
fi
