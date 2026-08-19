# Reproduzierbares Beispiel-Deployment

`hello-app` demonstriert den vollständigen Weg von Git über Argo CD bis zu einem ausschließlich im Heimnetz erreichbaren HTTPS-Endpunkt. Das Beispiel benötigt keine Secrets und keine persistente Ablage.

## Enthaltene Ressourcen

- Namespace mit erzwungenem Pod-Security-Profil `restricted`
- Deployment mit zwei Replikas, Probes, Ressourcenlimits und gehärtetem SecurityContext
- interner `ClusterIP`-Service
- lokaler Ingress für `hello.homelab.local`
- NetworkPolicy, die eingehenden Traffic nur von ingress-nginx erlaubt
- PodDisruptionBudget für Wartungsarbeiten

## Voraussetzungen

- Argo CD ist installiert und kann dieses Repository lesen.
- ingress-nginx und MetalLB sind bereit.
- `hello.homelab.local` zeigt im lokalen DNS auf die MetalLB-IP von ingress-nginx.
- das TLS-Secret `homelab-local-tls` ist im Namespace `hello-app` vorhanden. Da Kubernetes Secrets namespacegebunden sind, muss es dort separat erzeugt oder durch den Zertifikatsprozess bereitgestellt werden.

## Validieren

```bash
kubectl kustomize examples/hello-app/manifests
kubectl apply --dry-run=client -k examples/hello-app/manifests
```

## Über Argo CD deployen

```bash
kubectl apply -f examples/hello-app/argocd-application.yaml
kubectl wait application/hello-app \
  --namespace argocd \
  --for=jsonpath='{.status.health.status}'=Healthy \
  --timeout=5m
curl --fail --cacert /path/to/homelab-ca.pem https://hello.homelab.local/
```

Erwartete Antwort:

```text
hello from the homelab GitOps example
```

In einem Fork muss `repoURL` in `argocd-application.yaml` angepasst werden. Für einen rein lokalen Test kann alternativ `kubectl apply -k examples/hello-app/manifests` verwendet werden; der Argo-CD-Weg ist die maßgebliche reproduzierbare Variante.

## Entfernen

```bash
kubectl delete application hello-app --namespace argocd
```

Der Argo-CD-Finalizer entfernt dabei die vom Beispiel verwalteten Ressourcen.
