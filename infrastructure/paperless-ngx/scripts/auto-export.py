#!/usr/bin/env python3
"""
Paperless-NGX Auto-Export Script
Exportiert Dokumente automatisch basierend auf Tags in passende Unterordner
"""
import os
import sys
import shutil
from pathlib import Path

# Django Setup
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'paperless.settings')
import django
django.setup()

from documents.models import Document

def get_export_path(document):
    """Bestimmt den Export-Pfad basierend auf Tags und Correspondent"""
    base_export = Path("/usr/src/paperless/export")
    
    # Tag-basierte Zuordnung
    tag_mapping = {
        "Auto": "Auto",
        "Versicherung": "Finanz/Versicherungen",
        "Finanzen": "Finanz",
        "Wohnung": "Wohnung",
        "Familie": "Familie allg",
        "Behörde": "Behörde",
        "Wichtig": "wichtige Dateien"
    }
    
    # Prüfe Tags
    for tag in document.tags.all():
        if tag.name in tag_mapping:
            return base_export / tag_mapping[tag.name]
    
    # Prüfe Correspondent
    if document.correspondent:
        corresp_name = document.correspondent.name
        if "Auto" in corresp_name:
            return base_export / "Auto"
        elif "Versicherung" in corresp_name:
            return base_export / "Finanz/Versicherungen"
        elif "Finanz" in corresp_name or "Bank" in corresp_name:
            return base_export / "Finanz"
    
    # Fallback: Unbekannt
    return base_export / "Allgemein"

def export_document(document_id):
    """Exportiert ein Dokument in den passenden Ordner"""
    try:
        doc = Document.objects.get(id=document_id)
        
        # Quell-Datei (archivierte Version mit OCR)
        source_file = Path(doc.archive_path) if doc.has_archive_version else Path(doc.source_path)
        
        if not source_file.exists():
            print(f"❌ Quelldatei nicht gefunden: {source_file}", file=sys.stderr)
            return False
        
        # Ziel-Ordner bestimmen
        export_dir = get_export_path(doc)
        export_dir.mkdir(parents=True, exist_ok=True)
        
        # Dateiname: YYYY-MM-DD Titel.pdf
        date_str = doc.created.strftime("%Y-%m-%d")
        safe_title = "".join(c for c in doc.title if c.isalnum() or c in (' ', '-', '_')).strip()
        filename = f"{date_str} {safe_title}{source_file.suffix}"
        
        export_path = export_dir / filename
        
        # Dokument kopieren (nicht verschieben, damit Paperless es behält)
        shutil.copy2(source_file, export_path)
        
        print(f"✓ Exportiert: {export_path}")
        return True
        
    except Document.DoesNotExist:
        print(f"❌ Dokument {document_id} nicht gefunden", file=sys.stderr)
        return False
    except Exception as e:
        print(f"❌ Fehler beim Export: {e}", file=sys.stderr)
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: auto-export.py <document_id>", file=sys.stderr)
        sys.exit(1)
    
    document_id = int(sys.argv[1])
    success = export_document(document_id)
    sys.exit(0 if success else 1)
