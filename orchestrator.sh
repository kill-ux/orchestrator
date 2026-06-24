#!/bin/bash
# =============================================================================
# orchestrator.sh — single entry-point to manage the K3s Vagrant cluster.
#
# Usage:
#   ./orchestrator.sh create    boot VMs + provision K3s + configure kubectl
#   ./orchestrator.sh start     boot VMs (no-op if already running)
#   ./orchestrator.sh stop      gracefully halt the VMs
#   ./orchestrator.sh status    show VM and K8s node status
#   ./orchestrator.sh destroy   tear down the VMs and remove the kubeconfig
#   ./orchestrator.sh kubeconfig  print the kubectl context name
# =============================================================================


set -euo pipefail

MASTER_IP=${MASTER_IP:-192.168.56.10}
KUBECONFIG_HOST="$HOME/.kube/config"
KUBECONFIG_REMOTE="/etc/rancher/k3s/k3s.yaml"

RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[1;33m'
BLU='\033[0;34m'
NC='\033[0m'


log()  { echo -e "${GRN}[+]${NC} $*"; }
info() { echo -e "${BLU}[i]${NC} $*"; }
warn() { echo -e "${YEL}[!]${NC} $*"; }
err()  { echo -e "${RED}[-]${NC} $*" >&2; }

configure_kubectl() {
    mkdir -p $(dirname $KUBECONFIG_HOST)
    info "Fetching kubeconfig from master and rewriting server URL → $MASTER_IP"
    vagrant ssh master -c "sudo cat /etc/rancher/k3s/k3s.yaml" \
        | sed "s/127.0.0.1/$MASTER_IP/g" \
        > $KUBECONFIG_HOST
    
    chmod 600 "$KUBECONFIG_HOST"
    log "kubectl configured → ${KUBECONFIG_HOST}"
}

install_kubectl() {
    # Check if kubectl is already in the PATH
    if command -v kubectl &>/dev/null; then
        log "kubectl is already installed at $(which kubectl). Skipping."
        return 0
    fi

    log "Installing kubectl to ~/.local/bin ..."
    BINARIES_DIR=~/.local/bin/test
    mkdir -p $BINARIES_DIR

    # Get the latest stable version
    LATEST_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    
    curl -LO "https://dl.k8s.io/release/${LATEST_VERSION}/bin/linux/amd64/kubectl"
    curl -LO "https://dl.k8s.io/release/${LATEST_VERSION}/bin/linux/amd64/kubectl.sha256"

    if echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check --status; then
        log "Checksum verified successfully."
    else
        err "Checksum verification failed! Aborting."
        exit 1
    fi

    chmod +x kubectl
    mv kubectl ~/.local/bin/test/kubectl
    echo 'export PATH="$HOME/.local/bin/test:$PATH"' >> ~/.zshrc
    export PATH="~/.local/bin/test:$PATH"

    log "kubectl installed successfully at ~/.local/bin/kubectl"
}

cmd_create() {
    install_kubectl
    
    log "Creating K3s cluster (vagrant up + provisioning) ..."
    vagrant up --provision
    configure_kubectl

    echo
    log "Cluster is up. Nodes:"
    kubectl get nodes
}

usage() {
  sed -n '2,12p' "$0"   # print the header comment block
}

main() {
    case "${1:-}" in 
        create) cmd_create ;;
        *) err "Unknown command: ${1:-}"; usage; exit 1 ;;
    esac
}

main $@