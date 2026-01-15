#!/bin/bash
# Löscht fehlgeschlagene Velero-Kopia-Jobs, die mit kavita zu tun haben
# Kann als CronJob oder manuell ausgeführt werden

NAMESPACE=velero
PATTERN=kavita-default-kopia

kubectl get jobs -n "$NAMESPACE" | grep "$PATTERN" | awk '$3=="0/1" && $2=="Failed" {print $1}' | xargs -r kubectl delete job -n "$NAMESPACE"
