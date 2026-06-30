#!/bin/bash

# =============================================================================
# k3s-agent.sh — joins the AGENT node to the existing K3s cluster.
# =============================================================================


log()  { echo -e "\033[0;34m[agent]\033[0m $*"; }
warn() { echo -e "\033[1;33m[agent]\033[0m $*"; }
err()  { echo -e "\033[0;31m[agent]\033[0m $*" >&2; }

if systemctl is-active --quiet k3s-agent 2>/dev/null; then
    warn "k3s-agent is already active — skipping join."
    exit 0
fi

log "Waiting for $TOKEN_FILE (master must finish first) ..."
TIMEOUT=60
ELAPSED=0

while [[ ! -s $TOKEN_FILE ]]; do
    if (( ELAPSED >= TIMEOUT )); then
        err "Timed out waiting for ${TOKEN_FILE}. Is the master provisioned?"
        exit 1
    fi
    sleep 3
    ELAPSED=$((ELAPSED + 3))
done

TOKEN=$(cat "$TOKEN_FILE")

# joining
log "Joining cluster at https://$MASTER_IP:6443 ..."

mkdir -p /etc/rancher/k3s
cat > /etc/rancher/k3s/config.yaml <<EOF
server: "https://$MASTER_IP:6443"
token: "$TOKEN"
node-ip: "$AGENT_IP"
EOF

curl -sfL https://get.k3s.io | sh -s - agent --flannel-iface=eth1