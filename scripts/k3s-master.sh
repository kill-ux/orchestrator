#!/bin/bash

# =============================================================================
# k3s-server.sh — installs K3s server (control plane) on the MASTER node.
# =============================================================================

set -euo pipefail

log()  { echo -e "\033[0;32m[master]\033[0m $*"; }
warn() { echo -e "\033[1;33m[master]\033[0m $*"; }

if systemctl is-active --quiet k3s ; then
    warn "k3s service is already active — skipping install."
else
    log "Installing K3s server (--tls-san=$MASTER_IP) ..."
    mkdir -p /etc/rancher/k3s
    cat > /etc/rancher/k3s/config.yaml <<EOF
node-ip: $MASTER_IP
tls-san: 
  - $MASTER_IP
write-kubeconfig-mode: 644
EOF

    curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
fi

log "Waiting for https://${MASTER_IP}:6443/readyz ..."
for i in {1..60}; do
    if kubectl get --raw='/readyz' >/dev/null 2>&1; then
        log "API server is ready."
        break
    fi
    sleep 3
done

log "Publishing node-token → ${TOKEN_FILE}"

cat /var/lib/rancher/k3s/server/node-token > $TOKEN_FILE
chmod 600 $TOKEN_FILE