#!/bin/bash
set -e

# Paperless API Configuration
PAPERLESS_URL="http://paperless-ngx.paperless-ngx.svc.cluster.local"
PAPERLESS_USER="admin"
PAPERLESS_PASS="admin123"

echo "=== Paperless Auto-Matching Setup ==="
echo "Getting auth token..."

# Get auth token
TOKEN=$(kubectl exec -n paperless-ngx deployment/paperless-ngx -c paperless -- \
  curl -s -X POST "$PAPERLESS_URL/api/token/" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$PAPERLESS_USER\",\"password\":\"$PAPERLESS_PASS\"}" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "Error: Could not get auth token"
  exit 1
fi

echo "Token obtained successfully"

# Create Tag "Auto"
echo "Creating Tag 'Auto'..."
TAG_RESPONSE=$(kubectl exec -n paperless-ngx deployment/paperless-ngx -c paperless -- \
  curl -s -X POST "$PAPERLESS_URL/api/tags/" \
  -H "Authorization: Token $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Auto",
    "color": "#3498db",
    "matching_algorithm": 6,
    "match": "KFZ|Fahrzeug|Kraftfahrzeug|Auto|Kfz-Steuer|Zulassung|TÜV|Versicherung.*Fahrzeug",
    "is_insensitive": true
  }')

TAG_ID=$(echo "$TAG_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "Tag 'Auto' created with ID: $TAG_ID"

# Create Document Type "Auto/Fahrzeug"
echo "Creating Document Type 'Auto/Fahrzeug'..."
DOCTYPE_RESPONSE=$(kubectl exec -n paperless-ngx deployment/paperless-ngx -c paperless -- \
  curl -s -X POST "$PAPERLESS_URL/api/document_types/" \
  -H "Authorization: Token $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Auto/Fahrzeug",
    "matching_algorithm": 6,
    "match": "KFZ|Fahrzeug|Kraftfahrzeug|Zulassung|TÜV|HU|AU",
    "is_insensitive": true
  }')

DOCTYPE_ID=$(echo "$DOCTYPE_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "Document Type 'Auto/Fahrzeug' created with ID: $DOCTYPE_ID"

# Create Correspondent "Auto" (optional)
echo "Creating Correspondent 'Behörde/Auto'..."
CORRESP_RESPONSE=$(kubectl exec -n paperless-ngx deployment/paperless-ngx -c paperless -- \
  curl -s -X POST "$PAPERLESS_URL/api/correspondents/" \
  -H "Authorization: Token $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Behörde/Auto",
    "matching_algorithm": 6,
    "match": "Zollamt|Finanzamt.*KFZ|Zulassungsstelle|KFZ-Steuer",
    "is_insensitive": true
  }')

CORRESP_ID=$(echo "$CORRESP_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "Correspondent 'Behörde/Auto' created with ID: $CORRESP_ID"

echo ""
echo "=== Setup Complete ==="
echo "Tag ID: $TAG_ID"
echo "Document Type ID: $DOCTYPE_ID"
echo "Correspondent ID: $CORRESP_ID"
echo ""
echo "Neue Dokumente mit 'KFZ', 'Auto', 'Fahrzeug' etc. werden automatisch:"
echo "  - Tag 'Auto' erhalten"
echo "  - Document Type 'Auto/Fahrzeug' zugewiesen bekommen"
echo "  - Correspondent 'Behörde/Auto' (wenn Behörde im Text)"
echo ""
echo "Das existierende Dokument kann jetzt neu verarbeitet werden:"
echo "kubectl exec -n paperless-ngx deployment/paperless-ngx -c paperless -- \\
  curl -X POST \"$PAPERLESS_URL/api/documents/1/remake_classifiers/\" \\
  -H \"Authorization: Token $TOKEN\""
