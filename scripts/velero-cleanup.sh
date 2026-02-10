#!/bin/bash
# Velero Maintenance Cleanup Script
# Behebt Probleme mit orphaned BackupRepositories von gelöschten Apps

set -e

NAMESPACE="velero"
GRACE_PERIOD_FAILED_JOBS="${1:-3600}"  # Standard: 1h

echo "=== Velero Cleanup ===" 

# 1. Fehlgeschlagene Maintenance Jobs löschen
echo "1. Löschen fehlgeschlagener Maintenance Jobs..."
kubectl delete jobs -n $NAMESPACE --field-selector status.successful=0 2>/dev/null || echo "Keine fehlgeschlagenen Jobs gefunden"

# 2. Orphaned BackupRepositories identifizieren und löschen
echo "2. Prüfe auf orphaned BackupRepositories..."
ORPHANED=$(kubectl get backuprepository -n $NAMESPACE -o json | \
  jq -r '.items[] | select(.metadata.namespace | startswith("kube-system") | not) | .metadata.name' | \
  while read repo; do
    APP_NAME=$(echo $repo | cut -d'-' -f1-2)
    if ! kubectl get ns $APP_NAME &>/dev/null; then
      echo $repo
    fi
  done)

if [ -z "$ORPHANED" ]; then
  echo "Keine orphaned BackupRepositories gefunden"
else
  echo "Folgende BackupRepositories werden gelöscht:"
  echo "$ORPHANED"
  echo "$ORPHANED" | xargs -I {} kubectl delete backuprepository -n $NAMESPACE {}
fi

# 3. Status Report
echo ""
echo "=== Status nach Cleanup ==="
echo "Verbleibende BackupRepositories:"
kubectl get backuprepository -n $NAMESPACE --no-headers | wc -l
echo "Laufende Jobs:"
kubectl get jobs -n $NAMESPACE --no-headers | wc -l

echo "✅ Cleanup abgeschlossen"
