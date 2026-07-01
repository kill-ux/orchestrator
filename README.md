# Kubernetes Orchestrator Project

A complete microservices architecture deployed on a K3s cluster managed by Vagrant.
The project demonstrates container orchestration, scaling, secret management, and
stateful workload handling.

---

## Table of Contents

1. [Architecture](#-architecture)
2. [Prerequisites](#-prerequisites)
3. [Project Structure](#-project-structure)
4. [Configuration](#-configuration)
5. [Setup & Usage](#-setup--usage)
6. [Manifests Overview](#-manifests-overview)
7. [Troubleshooting](#-troubleshooting)
8. [Bonus Features](#-bonus-features)

---

## Architecture

```
                          ┌─────────────────┐
                          │   API Gateway   │ :3000 (NodePort 30000)
                          │   (Deployment)  │
                          └────────┬────────┘
                                   │
                  ┌────────────────┼────────────────┐
                  │                                 │
                  ▼                                 ▼
        ┌──────────────────┐              ┌──────────────────┐
        │  inventory-app   │              │   billing-app    │
        │   (Deployment)   │              │  (StatefulSet)   │
        │       :8080      │              │      :8080       │
        └────────┬─────────┘              └────────┬─────────┘
                 │                                 │
                 ▼                                 ▼
        ┌──────────────────┐              ┌──────────────────┐
        │   inventory-db   │              │    billing-db    │
        │  (StatefulSet)   │              │   (StatefulSet)  │
        │       :5432      │              │      :5432       │
        └──────────────────┘              └────────┬─────────┘
                                                  │
                                                  ▼
                                         ┌──────────────────┐
                                         │     RabbitMQ     │
                                         │   (Deployment)   │
                                         │  :5672 / :15672  │
                                         └──────────────────┘
```

### Components

| Component       | Type        | Port  | Image                            |
|-----------------|-------------|-------|----------------------------------|
| `inventory-db`  | StatefulSet | 5432  | `killux3k/inventory-db:1.0.0`    |
| `billing-db`    | StatefulSet | 5432  | `killux3k/billing-db:1.0.0`      |
| `rabbitmq`      | Deployment  | 5672  | `killux3k/billing-queue:1.0.0`   |
| `inventory-app` | Deployment  | 8080  | `killux3k/inventory-app:1.0.0`   |
| `billing-app`   | StatefulSet | 8080  | `killux3k/billing-app:1.0.0`     |
| `api-gateway`   | Deployment  | 3000  | `killux3k/api-gateway:1.0.0`     |

### Resource Limits & Scaling

| Component       | Replicas (min/max) | CPU Target | Storage |
|-----------------|--------------------|------------|---------|
| `inventory-db`  | 1 (fixed)          | —          | 1Gi PVC |
| `billing-db`    | 1 (fixed)          | —          | 1Gi PVC |
| `rabbitmq`      | 1 (fixed)          | —          | 1Gi PVC |
| `inventory-app` | 1 / 3              | 60%        | —       |
| `billing-app`   | 1 (fixed)          | —          | —       |
| `api-gateway`   | 1 / 3              | 60%        | —       |

---

## Prerequisites

### Host Machine
- **OS**: Linux / macOS / Windows (with WSL2)
- **RAM**: 4 GB free (for both VMs)
- **Disk**: 10 GB free
- **Tools**:
  - [Vagrant](https://www.vagrantup.com/downloads) (≥ 2.3)
  - [VirtualBox](https://www.virtualbox.org/wiki/Downloads) (≥ 7.0)
  - `curl` (used by the orchestrator script)
  - `ssh` (for Vagrant)

### Cluster Nodes
Each VM runs:
- Ubuntu 24.04 (Bento box)
- 2 GB RAM
- 2 CPUs
- K3s v1.35 (installed by provisioners)

### Docker Hub
A Docker Hub account with 6 public images pushed (or accessible):
- `killux3k/inventory-db:1.0.0`
- `killux3k/billing-db:1.0.0`
- `killux3k/billing-queue:1.0.0`
- `killux3k/inventory-app:1.0.0`
- `killux3k/billing-app:1.0.0`
- `killux3k/api-gateway:1.0.0`

> **Note**: Replace `killux3k` with your own Docker Hub username in all manifests.

---

## Project Structure

```
.
├── Manifests/                    # Kubernetes manifests
│   ├── 00-namespace.yaml
│   ├── 01-secrets.yaml
│   ├── 02-storageclass.yaml
│   ├── 03-inventory-db.yaml      # StatefulSet + headless Service
│   ├── 04-billing-db.yaml        # StatefulSet + headless Service
│   ├── 05-rabbitmq.yaml          # Deployment + Service + PVC
│   ├── 06-inventory-app.yaml     # Deployment + Service + HPA
│   ├── 07-billing-app.yaml       # StatefulSet + headless Service
│   └── 08-api-gateway.yaml       # Deployment + NodePort Service + HPA
│
├── Scripts/                      # Provisioning & utility scripts
│   ├── k3s-server.sh             # Installs K3s on master
│   └── k3s-agent.sh              # Joins agent to cluster
│
├── Vagrantfile                   # Defines master + agent VMs
├── orchestrator.sh               # Manages the cluster lifecycle
└── README.md                     # This file
```

---

## Configuration

### Network Layout

| Node    | IP              | Role                |
|---------|-----------------|---------------------|
| master  | 192.168.56.10   | K3s server (control plane) |
| agent   | 192.168.56.11   | K3s agent (worker)  |

Both VMs communicate over VirtualBox's `vboxnet0` host-only network (192.168.56.0/24).

### K3s Versions & Settings
- K3s server flag: `--tls-san=192.168.56.10` (allows kubectl from host)
- Kubeconfig mode: `0644` (readable by vagrant user)
- Default StorageClass: `local-path` (K3s default)

### Environment Variables (per component)

**inventory-db / billing-db** — set by `setup_db.sh`:
- `DB_USER`, `DB_PASS`, `DB_NAME`

**inventory-app**:
- `INVENTORY_APP_PORT=8080`
- `INVENTORY_DB_HOST=inventory-db-svc`
- `INVENTORY_DB_PORT=5432`
- `INVENTORY_DB_USER` / `_PASS` / `_NAME` (from Secret)

**billing-app**:
- `BILLING_APP_PORT=8080`
- `BILLING_DB_HOST=billing-db-svc`
- `BILLING_DB_PORT=5432`
- `BILLING_DB_USER` / `_PASS` / `_NAME` (from Secret)
- `RABBITMQ_HOST=rabbitmq-svc`
- `RABBITMQ_PORT=5672`
- `RABBITMQ_QUEUE=billing_queue`
- `RABBITMQ_USER` / `_PASS` (from Secret)

**api-gateway**:
- `APIGATEWAY_PORT=3000`
- `INVENTORY_APP_HOST=inventory-app-svc`
- `INVENTORY_APP_PORT=8080`
- `BILLING_APP_HOST=billing-app-svc`
- `BILLING_APP_PORT=8080`

---

## Setup & Usage

### 1. Clone the repository
```bash
git clone https://github.com/kill-ux/orchestrator.git
cd orchestrator
```

### 2. Update credentials
Copy `Manifests/01-secrets.yaml.example` to `Manifests/01-secrets.yaml` and replace the placeholder values:
```yaml
stringData:
  DB_NAME: your_actual_db_name
  DB_PASS: your_actual_password
  DB_USER: your_actual_user
```

### 3. Start the cluster

```bash
./orchestrator.sh create
```

This command:
1.  Installs `kubectl` on your host (if missing)
2.  Boots the master and agent VMs via Vagrant
3.  Provisions K3s on both nodes (via `Scripts/k3s-server.sh` and `Scripts/k3s-agent.sh`)
4.  Waits for the master API to be ready
5.  Configures `~/.kube/config` to point at the master
6.  Verifies both nodes are `Ready`

Expected output:
```
[+] kubectl installed successfully at /home/user/.local/bin/kubectl
[+] Creating K3s cluster (vagrant up + provisioning) ...
[+] API is ready.
[+] Joining cluster at https://192.168.56.10:6443 ...
[+] Cluster is up. Nodes:
NAME     STATUS   ROLES           AGE   VERSION
agent    Ready    <none>          30s   v1.35.5+k3s1
master   Ready    control-plane   60s   v1.35.5+k3s1
```

### 4. Deploy the application stack

```bash
kubectl apply -f Manifests/
```

This applies all manifests in dependency order. Verify:
```bash
kubectl get all -n orchestrator
```

Expected output includes:
- 2 StatefulSets (DBs) — 1/1 each
- 3 Deployments (rabbitmq, inventory-app, api-gateway)
- 1 StatefulSet (billing-app) — 1/1
- 2 HPAs (api-gateway, inventory-app)
- All Services with their ports
- 3 Secrets
- 1 Namespace

### 5. Verify connectivity

```bash
# From your host, hit the API gateway
curl http://192.168.56.10:30000/

```

### 6. Day-to-day operations

```bash
./orchestrator.sh start    
./orchestrator.sh stop    
./orchestrator.sh status   
```

---

## Manifests Overview

### `00-namespace.yaml`
Creates the `orchestrator` namespace. All resources are deployed inside it for
isolation and easy cleanup (`kubectl delete ns orchestrator`).

### `01-secrets.yaml`
Stores credentials as K8s `Secret` objects:
- `inventory-db-credentials` (DB_USER, DB_PASS, DB_NAME)
- `billing-db-credentials` (DB_USER, DB_PASS, DB_NAME)
- `rabbitmq-credentials` (RABBITMQ_USER, RABBITMQ_PASS,...)

Per project requirement: passwords and credentials are **never** inlined in
non-secret manifests.

### `02-inventory-db.yaml` & `03-billing-db.yaml`
- **StatefulSet** with `replicas: 1` (single DB instance, no clustering)
- **Headless Service** (`clusterIP: None`) for stable per-pod DNS
- **PVC** of 1Gi via `volumeClaimTemplates` (data persists across pod restarts)
- **Env vars** from the corresponding Secret (`DB_USER`, `DB_PASS`, `DB_NAME`)
- **Mount path** `/var/lib/postgresql/main` (matches the custom DB image's setup script)

### `04-rabbitmq.yaml`
- **Deployment** with `replicas: 1` (stateless-ish; PVC for message durability)
- **ClusterIP Service** exposing AMQP (5672)
- **Standalone PVC** for message persistence (separate from StatefulSet's `volumeClaimTemplates`)
- **Credentials** from `rabbitmq-credentials` Secret

### `05-inventory-app.yaml`
- **Deployment** (stateless — no PVC)
- **ClusterIP Service** for internal access (port 8080)
- **HPA**: 1↔3 replicas, CPU 60% target
- **Resources**: requests `100m CPU / 128Mi RAM`, limits `500m / 256Mi`

### `06-billing-app.yaml`
- **StatefulSet** with `replicas: 1` 
- **Headless Service** (`clusterIP: None`)
- **No PVC** (the app doesn't persist local state; it consumes from RabbitMQ)
- Connects to both `billing-db-svc` and `rabbitmq-svc`

### `07-api-gateway.yaml`
- **Deployment** (stateless)
- **NodePort Service** (port 30000 on each node) — reachable from outside the cluster
- **HPA**: 1↔3 replicas, CPU 60% target
- Forwards HTTP requests to `inventory-app-svc` and `billing-app-svc`

---

## Troubleshooting

### Pod stuck in `Pending`
- Check `kubectl describe pod <name> -n orchestrator`
- Common cause: PVC not bound → check `kubectl get pvc -n orchestrator`
- Common cause: image pull error → verify image name/tag on Docker Hub

### Pod stuck in `CrashLoopBackOff`
- Check logs: `kubectl logs -n orchestrator <pod> --previous`
- Common cause: wrong env var from Secret (key mismatch)
- Common cause: app can't connect to backend (DNS, wrong hostname)

### CoreDNS issues
If pods can't resolve service names:
```bash
kubectl rollout restart deployment coredns -n kube-system
```

### Cluster unreachable from host
```bash
# Check kubeconfig
cat ~/.kube/config | head

# Re-fetch from master
vagrant ssh master -c "sudo cat /etc/rancher/k3s/k3s.yaml" \
  | sed "s/127.0.0.1/192.168.56.10/g" > ~/.kube/config
```

### Complete reset
```bash
vagrant destroy -f
./orchestrator.sh create
```

---

## References

- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
- [Vagrant Multi-Machine](https://developer.hashicorp.com/vagrant/docs/multi-machine)
- [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [HorizontalPodAutoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)

---

## Author

Built as part of the **Orchestrator** project — Kubernetes introduction through
hands-on deployment of a complete microservices architecture.

For questions or issues, please open an issue in the repository.