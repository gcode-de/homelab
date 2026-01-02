#!/usr/bin/env python3
"""
Exportiert alle existierenden Dokumente
"""
import os
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'paperless.settings')
import django
django.setup()

from documents.models import Document
import subprocess

print("=== Exportiere alle Dokumente ===")
documents = Document.objects.all()
total = documents.count()
success = 0

for i, doc in enumerate(documents, 1):
    print(f"[{i}/{total}] {doc.title}...", end=" ")
    result = subprocess.run(
        ["/usr/src/paperless/scripts/auto-export.py", str(doc.id)],
        capture_output=True,
        text=True
    )
    if result.returncode == 0:
        print("✓")
        success += 1
    else:
        print("✗")
        if result.stderr:
            print(f"  Fehler: {result.stderr.strip()}")

print(f"\n✓ {success}/{total} Dokumente erfolgreich exportiert")
