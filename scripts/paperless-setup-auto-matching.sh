#!/usr/bin/env bash
set -euo pipefail

# Paperless API Configuration
PAPERLESS_URL="${PAPERLESS_URL:-http://paperless-ngx.paperless-ngx.svc.cluster.local}"
PAPERLESS_USER="${PAPERLESS_USER:-admin}"

command -v jq >/dev/null 2>&1 || {
  echo "Error: jq is required" >&2
  exit 1
}

if [[ -z "${PAPERLESS_PASS:-}" ]]; then
  if [[ -t 0 ]]; then
    read -r -s -p "Paperless password: " PAPERLESS_PASS
    echo
  else
    echo "Error: set PAPERLESS_PASS for non-interactive use" >&2
    exit 1
  fi
fi

trap 'unset TOKEN PAPERLESS_PASS' EXIT

echo "=== Paperless Auto-Matching Setup ==="
echo "Getting auth token..."

# Get auth token
TOKEN=$(
  jq -nc \
    --arg username "$PAPERLESS_USER" \
    --arg password "$PAPERLESS_PASS" \
    '{username: $username, password: $password}' |
    kubectl exec -i -n paperless-ngx deployment/paperless-ngx -c paperless -- \
      curl -fsS -X POST "$PAPERLESS_URL/api/token/" \
      -H "Content-Type: application/json" \
      --data-binary @- |
    jq -er '.token'
)

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

TAG_ID=$(jq -er '.id' <<<"$TAG_RESPONSE")
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

DOCTYPE_ID=$(jq -er '.id' <<<"$DOCTYPE_RESPONSE")
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

CORRESP_ID=$(jq -er '.id' <<<"$CORRESP_RESPONSE")
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
echo "Dazu die Paperless-Oberfläche oder einen neuen, separat authentifizierten API-Aufruf verwenden."
