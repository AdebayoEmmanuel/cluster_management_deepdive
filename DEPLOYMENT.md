# DEPLOYMENT.md
## Kubernetes E-Commerce Platform Deployment

---

## Overview

This project deploys a **multi-tier e-commerce platform** on Kubernetes using **explicit scheduling controls** instead of default behavior.

The deployment emphasizes:

- Deterministic pod placement
- Isolation via taints and tolerations
- High availability using affinity and anti-affinity
- Priority-based scheduling and preemption
- Static pods for node-level monitoring

This reflects **production-grade Kubernetes operations**, not tutorial defaults.

---

## Cluster Architecture

### Nodes

| Node | Role | Labels | Taints |
|---|---|---|---|
| control-plane | Control Plane | — | — |
| worker-node-1 | Frontend | `environment=production`<br>`storage=ssd`<br>`tier=frontend` | `workload=frontend:NoSchedule` |
| worker-node-2 | Backend | `environment=production`<br>`storage=hdd`<br>`tier=backend` | `workload=backend:NoSchedule` |

---

## Namespace

All workloads are deployed in a dedicated namespace.

```bash
kubectl create namespace ecommerce
kubectl config set-context --current --namespace=ecommerce


Workload Design
PostgreSQL (Database)

Type: Deployment (1 replica)

Image: postgres:16

Placement: Backend node only

Controls: nodeSelector + backend toleration

Service: ClusterIP (internal)

Reasoning: Stateful workload with strict isolation

Redis (Cache Layer)

Type: Deployment (2 replicas)

Image: redis:7-alpine

Placement: Spread across nodes

Controls: Required pod anti-affinity

Service: ClusterIP

Reasoning: High availability and node failure resilience

Backend API

Type: Deployment (3 replicas)

Image: nginx:alpine

Placement:

Required: Backend tier

Preferred: SSD storage

Controls: Node affinity + backend toleration

Service: ClusterIP (8080 → 80)

Environment Variables:

DATABASE_HOST=postgres

REDIS_HOST=redis

Reasoning: Deterministic scheduling with performance optimization

Frontend

Type: Deployment (4+ replicas)

Image: nginx:alpine

Placement: Frontend tier only

Controls: nodeSelector + frontend toleration

Service: NodePort (30080)

Reasoning: Horizontally scalable, externally accessible workload

Monitoring Agent (Static Pod)

Type: Static Pod

Node: worker-node-1

Path: /etc/kubernetes/manifests

Namespace: kube-system

Reasoning: Node-level monitoring independent of the API server

Priority & Preemption

Two priority classes are defined:

high-priority → frontend workloads

low-priority → batch/background workloads

Under resource pressure, low-priority pods are preempted first to guarantee availability of critical services.

Deployment Order
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/postgres/
kubectl apply -f manifests/redis/
kubectl apply -f manifests/backend/
kubectl apply -f manifests/frontend/
kubectl apply -f manifests/priority/


Static pods are deployed directly on the node filesystem.

Verification
Cluster State
kubectl get nodes --show-labels
kubectl get pods -o wide
kubectl get svc

Pod Scheduling
kubectl describe pod <pod-name>

Service Connectivity
kubectl run test --image=curlimages/curl --rm -it -- sh

curl http://backend:8080
nslookup postgres
nslookup redis

Failure Behavior

Draining a node reschedules stateless workloads

Static pods are recreated automatically by kubelet

Pod anti-affinity prevents unsafe co-location

Priority classes protect critical workloads under pressure

Cleanup
kubectl delete namespace ecommerce

kubectl label nodes worker-node-1 environment- storage- tier-
kubectl label nodes worker-node-2 environment- storage- tier-

kubectl taint nodes worker-node-1 workload=frontend:NoSchedule-
kubectl taint nodes worker-node-2 workload=backend:NoSchedule-


Static pod removal:

ssh ubuntu@worker-node-1
sudo rm /etc/kubernetes/manifests/monitoring-agent.yaml

Engineering Principles Applied

Explicit scheduling over implicit defaults

Failure-aware workload design

Resource guarantees, not best-effort

Clear separation of concerns

Reproducible, auditable deployments