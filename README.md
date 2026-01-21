

```markdown
# Kubernetes E-Commerce Platform Deployment

Production-grade Kubernetes deployment demonstrating advanced scheduling, service discovery, high availability, and cluster management concepts.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Components](#components)
- [Scheduling Strategy](#scheduling-strategy)
- [Deployment](#deployment)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Key Learnings](#key-learnings)

## Overview

This project implements a multi-tier e-commerce platform on Kubernetes with explicit scheduling controls, demonstrating:

- **Deterministic pod placement** using node selectors, affinity, and anti-affinity
- **Workload isolation** via taints and tolerations
- **High availability** through replica distribution and anti-affinity rules
- **Service discovery** using Kubernetes DNS and ClusterIP services
- **Static pods** for node-level monitoring
- **Priority-based scheduling** for critical workload protection

**Target Namespace:** `ecommerce`

## Architecture

### Cluster Topology

| Node | Role | Labels | Taints |
|------|------|--------|--------|
| control-plane | Control Plane | - | - |
| worker-node-1 | Frontend | `environment=production`, `storage=ssd`, `tier=frontend` | `workload=frontend:NoSchedule` |
| worker-node-2 | Backend | `environment=production`, `storage=hdd`, `tier=backend` | `workload=backend:NoSchedule` |

### Application Stack

```text
External Traffic
       |
       v
+--------------+
|   Frontend   | (NodePort :30080)
|  4 replicas  | -> worker-node-1
+------+-------+
       |
       v
+--------------+
|   Backend    | (ClusterIP :8080)
|  3 replicas  | -> worker-node-2
+------+-------+
       |
       v
+--------------+      +--------------+
|  Postgres    |      |    Redis     |
|  1 replica   |      |  2 replicas  |
+--------------+      +--------------+
   worker-node-2      Distributed
```

## Prerequisites

- Kubernetes cluster (v1.28+)
  - 1 control plane node
  - 2 worker nodes minimum
- `kubectl` configured and authenticated
- Bash shell (Linux/macOS/WSL)
- Sufficient cluster resources:
  - CPU: 4+ cores across workers
  - Memory: 8+ GB across workers

## Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd cluster_management_deepdive

# Make scripts executable
chmod +x scripts/deploy-all.sh scripts/cleanup.sh

# Deploy the entire stack
./scripts/deploy-all.sh

# Verify deployment
kubectl get pods -n ecommerce -o wide
kubectl get svc -n ecommerce

# Test the application
curl http://<worker-node-ip>:30080
```

## Project Structure

```text
cluster_management_deepdive/
├── README.md                          # This file
├── DEPLOYMENT.md                      # Detailed deployment guide
├── ANSWER.md                          # Assignment answers
├── docs/
│   └── architecture-diagram.md        # Architecture visualization
├── manifests/
│   ├── backend/
│   │   ├── backend-deployment.yaml    # Backend API deployment
│   │   └── backend-service.yaml       # Backend ClusterIP service
│   ├── frontend/
│   │   ├── frontend-deployment.yaml   # Frontend web deployment
│   │   └── frontend-service.yaml      # Frontend NodePort service
│   ├── postgres/
│   │   ├── postgres-deployment.yaml   # PostgreSQL database
│   │   └── postgres-service.yaml      # Postgres ClusterIP service
│   ├── redis/
│   │   ├── redis-deployment.yaml      # Redis cache with anti-affinity
│   │   └── redis-service.yaml         # Redis ClusterIP service
│   ├── monitoring/
│   │   └── monitoring-agent.yaml      # Static pod manifest
│   ├── priority/
│   │   └── priority-classes.yaml      # High/low priority classes
│   ├── batch-job-deployment.yaml      # Low-priority batch workload
│   ├── broken-app.yaml                # Intentionally broken manifest
│   └── fixed-broken-app.yaml          # Fixed version
├── scripts/
│   ├── deploy-all.sh                  # Automated deployment
│   ├── cleanup.sh                     # Cluster cleanup
│   └── Usage.md                       # Script usage guide
└── screenshots/                       # Validation screenshots
```

## Components

### PostgreSQL Database
- **Image:** postgres:16
- **Replicas:** 1
- **Placement:** Backend tier (worker-node-2)
- **Service:** ClusterIP on port 5432
- **Scheduling:** Node selector + backend toleration
- **Resources:** 500m CPU, 512Mi memory (requested)

### Redis Cache
- **Image:** redis:7-alpine
- **Replicas:** 2
- **Placement:** Distributed across both worker nodes
- **Service:** ClusterIP on port 6379
- **Scheduling:** Required pod anti-affinity
- **Resources:** 250m CPU, 256Mi memory (requested)

**Anti-Affinity Rule:**
```yaml
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchLabels:
          app: redis
      topologyKey: kubernetes.io/hostname
```

### Backend API
- **Image:** nginx:alpine
- **Replicas:** 3
- **Placement:** Backend tier with SSD preference
- **Service:** ClusterIP on port 8080
- **Environment:**
  - `DATABASE_HOST=postgres`
  - `REDIS_HOST=redis`
- **Scheduling:** Required node affinity + preferred SSD
- **Resources:** 200m CPU, 256Mi memory (requested)

### Frontend
- **Image:** nginx:alpine
- **Replicas:** 4
- **Placement:** Frontend tier (worker-node-1)
- **Service:** NodePort on port 30080
- **Environment:**
  - `BACKEND_URL=http://backend:8080`
- **Scheduling:** Node selector + frontend toleration
- **Resources:** 100m CPU, 128Mi memory (requested)

### Monitoring Agent (Static Pod)
- **Image:** busybox:latest
- **Type:** Static Pod
- **Location:** worker-node-1
- **Manifest Path:** `/etc/kubernetes/manifests/monitoring-agent.yaml`
- **Namespace:** `kube-system`
- **Purpose:** Node-level monitoring independent of API server

## Scheduling Strategy

### Node Affinity
**Backend Deployment:**
- **Required:** `tier=backend` (hard constraint)
- **Preferred:** `storage=ssd` (soft preference)

This ensures backend pods run on designated nodes while optimizing for performance when possible.

### Pod Anti-Affinity
**Redis Deployment:**
- `requiredDuringSchedulingIgnoredDuringExecution`

Prevents Redis replicas from co-locating on the same node, ensuring high availability during node failures.

### Taints and Tolerations
**Worker Node Taints:**
- `worker-node-1`: `workload=frontend:NoSchedule`
- `worker-node-2`: `workload=backend:NoSchedule`

**Pod Tolerations:**
- Frontend pods tolerate `workload=frontend`
- Backend/Postgres pods tolerate `workload=backend`
- Redis pods tolerate both (for distribution)

### Priority Classes
- **high-priority** (value: 1000): Frontend workloads
- **low-priority** (value: 100): Batch processing

Under resource pressure, low-priority pods are preempted to protect critical services.

## Deployment

### Automated Deployment
```bash
# Deploy everything
./scripts/deploy-all.sh
```
This script:
1. Creates the `ecommerce` namespace
2. Deploys PostgreSQL
3. Deploys Redis with anti-affinity
4. Deploys Backend API
5. Deploys Frontend
6. Applies monitoring configuration

### Manual Deployment
```bash
# Create namespace
kubectl create namespace ecommerce
kubectl config set-context --current --namespace=ecommerce

# Deploy in order
kubectl apply -f manifests/postgres/
kubectl apply -f manifests/redis/
kubectl apply -f manifests/backend/
kubectl apply -f manifests/frontend/
kubectl apply -f manifests/priority/
```

### Static Pod Deployment
SSH into `worker-node-1`:
```bash
ssh ubuntu@<worker-node-1-ip>
sudo mkdir -p /etc/kubernetes/manifests
sudo cp manifests/monitoring/monitoring-agent.yaml /etc/kubernetes/manifests/
```
The kubelet will automatically create the pod.

## Verification

### Check Pod Distribution
```bash
# View all pods with node placement
kubectl get pods -n ecommerce -o wide

# Verify Redis pods on different nodes
kubectl get pods -n ecommerce -l app=redis -o wide

# Check static pod
kubectl get pods -n kube-system | grep monitoring-agent
```

### Test Service Discovery
```bash
# Create a test pod
kubectl run test-pod -n ecommerce \
  --image=curlimages/curl \
  --rm -it --restart=Never -- sh

# Inside the pod
curl http://backend:8080
nslookup postgres
nslookup redis
exit
```

### Verify External Access
```bash
# Get worker node IP
kubectl get nodes -o wide

# Access frontend
curl http://<worker-node-ip>:30080
```

### Check Scheduling Constraints
```bash
# Describe a pod to see scheduling decisions
kubectl describe pod <pod-name> -n ecommerce

# Check node labels
kubectl get nodes --show-labels

# Check node taints
kubectl describe node <node-name> | grep -i taint
```

## Troubleshooting

### Pods Stuck in Pending
```bash
# Describe a pod to see scheduling decisions
kubectl describe pod <pod-name> -n ecommerce

# Check node labels
kubectl get nodes --show-labels

# Check node taints
kubectl describe node <node-name> | grep -i taint
```

### Service Connectivity Issues
```bash
# Verify service endpoints
kubectl get endpoints -n ecommerce

# Check service definition
kubectl describe svc <service-name> -n ecommerce

# Test from within cluster
kubectl run test --image=busybox -n ecommerce --rm -it -- sh
```

### Static Pod Not Starting
```bash
# Check kubelet logs on the node
ssh ubuntu@<node-ip>
sudo journalctl -u kubelet -f

# Verify manifest path
sudo cat /var/lib/kubelet/config.yaml | grep staticPodPath

# Check manifest syntax
sudo cat /etc/kubernetes/manifests/monitoring-agent.yaml
```

### Resource Constraints
```bash
# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -n ecommerce

# View resource requests/limits
kubectl describe nodes
```

## Cleanup

### Quick Cleanup
```bash
# Remove entire namespace (removes all workloads)
./scripts/cleanup.sh
```

### Complete Cleanup
```bash
# Delete namespace
kubectl delete namespace ecommerce

# Remove node labels
kubectl label nodes worker-node-1 environment- storage- tier-
kubectl label nodes worker-node-2 environment- storage- tier-

# Remove node taints
kubectl taint nodes worker-node-1 workload=frontend:NoSchedule-
kubectl taint nodes worker-node-2 workload=backend:NoSchedule-

# Remove static pod (requires SSH access to worker node)
ssh ubuntu@<worker-node-1-ip>
sudo rm /etc/kubernetes/manifests/monitoring-agent.yaml
```

## Key Learnings

### Scheduling Concepts
- **Required vs Preferred Affinity:**
  - `requiredDuringScheduling`: Hard constraint (pod will not schedule if unmet)
  - `preferredDuringScheduling`: Soft preference (best effort)
- **Pod Anti-Affinity:**
  - Prevents co-location of replicas
  - Critical for high availability
  - Can block scaling if nodes are insufficient
- **Taints and Tolerations:**
  - Provide workload isolation
  - Complement node selectors
  - Enable dedicated node pools
- **Static Pods:**
  - Managed by kubelet, not API server
  - Survive control plane failures
  - Ideal for node-level system components
  - Cannot be deleted via `kubectl delete` (must remove manifest file)

### Service Discovery
- ClusterIP services provide stable internal endpoints
- Kubernetes DNS resolves `<service-name>.<namespace>.svc.cluster.local`
- NodePort exposes services externally on all node IPs

### Resource Management
- Always set resource requests to ensure guaranteed scheduling
- Priority classes protect critical workloads
- Resource quotas prevent cluster resource exhaustion

### Best Practices
- Use namespaces for workload isolation
- Implement affinity rules for high availability
- Set appropriate resource requests and limits
- Use labels and selectors consistently
- Document scheduling decisions
- Test failure scenarios
- Automate deployments for reproducibility
```
