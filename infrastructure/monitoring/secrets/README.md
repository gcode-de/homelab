# Monitoring Secrets

This directory contains instructions for creating secrets that should NOT be committed to Git.

## Proxmox VE Exporter Credentials

The PVE Exporter needs API credentials to query your Proxmox hosts.
The same credentials work for ALL 6 Proxmox nodes (pve1, pve2, pve3, pve4, pve6, pve7).

### Proxmox Hosts:
- pve1: 192.168.68.211
- pve2: 192.168.68.212
- pve3: 192.168.68.213
- pve4: 192.168.68.214
- pve6: 192.168.68.216
- pve7: 192.168.68.217

### Create the secret manually:

```bash
kubectl create secret generic proxmox-credentials -n monitoring \
  --from-literal=user="prometheus@pve" \
  --from-literal=token_name="monitoring" \
  --from-literal=token_value="YOUR_TOKEN_VALUE_HERE"
```

### Or create from a file:

1. Create a file `proxmox-credentials.unsealed.yaml` (this will be gitignored):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: proxmox-credentials
  namespace: monitoring
type: Opaque
stringData:
  user: "prometheus@pve"
  token_name: "monitoring"
  token_value: "YOUR_TOKEN_VALUE_HERE"
```

2. Apply it:
```bash
kubectl apply -f proxmox-credentials.unsealed.yaml
```

## Proxmox API Token Creation

If you need to create a new token on your Proxmox host:

```bash
# SSH into any Proxmox node
ssh root@pve1.home.lan

# Create user (if not exists)
pveum user add prometheus@pve

# Grant PVEAuditor role (read-only access)
pveum aclmod / -user prometheus@pve -role PVEAuditor

# Create API token
pveum user token add prometheus@pve monitoring -privsep 0
```

This will output:
```
┌──────────────┬──────────────────────────────────────┐
│ key          │ value                                │
╞══════════════╪══════════════════════════════════════╡
│ full-tokenid │ prometheus@pve!monitoring            │
├──────────────┼──────────────────────────────────────┤
│ value        │ xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx │
└──────────────┴──────────────────────────────────────┘
```

Use the `value` field as `token_value` in the secret.

## Grafana Admin Password

The default Grafana admin password is set in `kube-prometheus-stack.yaml`.

**Important:** Change this password immediately after first login!

1. Login to Grafana: https://grafana-homelab-local or https://grafana.lab.samuelgesang.de
2. Username: `admin`
3. Password: `admin123` (default)
4. Go to: Administration → Users → admin → Change Password

## Alertmanager Secrets (Optional)

If you want to configure alerting via Slack, Discord, or Email, you'll need additional secrets.

### Slack Webhook:
```bash
kubectl create secret generic alertmanager-slack -n monitoring \
  --from-literal=webhook-url="https://hooks.slack.com/services/..."
```

### SMTP for Email:
```bash
kubectl create secret generic alertmanager-smtp -n monitoring \
  --from-literal=password="your-smtp-password"
```

Then update the Alertmanager configuration in `kube-prometheus-stack.yaml` to use these secrets.
