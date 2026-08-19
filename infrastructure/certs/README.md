# Lokales TLS-Zertifikat für `*.homelab.local`

Das Wildcard-Zertifikat wird mit mkcert erzeugt und von lokalen Browsern über
die installierte mkcert-CA vertraut. Es wird nicht von cert-manager erneuert.

```bash
mkcert "*.homelab.local" "homelab.local"
```

Kubernetes-TLS-Secrets sind namespacegebunden. Das Zertifikat muss deshalb in
jedem Namespace vorhanden sein, dessen Ingress `homelab-local-tls` referenziert:

```bash
for namespace in argocd monitoring portainer-ui; do
  kubectl create secret tls homelab-local-tls \
    --namespace "$namespace" \
    --cert=_wildcard.homelab.local+1.pem \
    --key=_wildcard.homelab.local+1-key.pem \
    --dry-run=client -o yaml | kubectl apply -f -
done
```

NetBox verwendet derzeit internes HTTP. Falls dort TLS aktiviert wird, muss das
Secret zusätzlich im Namespace `netbox` angelegt werden. Zertifikatsdateien und
private Schlüssel dürfen nicht in dieses Repository committed werden.
