# ANSWERS.md
## Kubernetes E-Commerce Platform – Scheduling & Architecture Answers

---

## Part 2 – PostgreSQL

### 1. On which node did the postgres pod get scheduled? Why?

The PostgreSQL pod was scheduled on **worker-node-2**.

**Reason:**
- The pod uses a `nodeSelector` targeting `tier=backend`
- The node is tainted with `workload=backend:NoSchedule`
- The pod explicitly tolerates this taint

Kubernetes had **only one valid node** that satisfied *all* scheduling constraints.

---

### 2. What happens if you remove the toleration?

The pod remains in **Pending** state.

**Why:**
- `worker-node-2` is tainted with `workload=backend:NoSchedule`
- Without a toleration, the scheduler is forbidden from placing the pod there

This demonstrates how taints provide **hard isolation guarantees**.

---

### 3. Can you access PostgreSQL from outside the cluster?

No.

**Reason:**
- PostgreSQL is exposed using a **ClusterIP** service
- ClusterIP services are only reachable **inside the cluster network**

This is intentional and aligns with **security best practices**.

---

## Part 3 – Redis (Affinity & Anti-Affinity)

### 1. Are the Redis pods running on different nodes? Why?

Yes.

**Reason:**
- Pod anti-affinity is configured with  
  `requiredDuringSchedulingIgnoredDuringExecution`
- Redis pods are forbidden from sharing the same hostname
- Kubernetes enforces this rule strictly at scheduling time

---

### 2. What happens if you scale Redis to 3 replicas with only 2 worker nodes?

The third pod remains **Pending**.

**Why:**
- Required pod anti-affinity cannot be satisfied
- Kubernetes will not violate a *required* rule even if resources are available

This is a **safety-over-availability tradeoff**.

---

### 3. What changes when using `preferredDuringSchedulingIgnoredDuringExecution`?

**Difference:**

| Required | Preferred |
|---|---|
| Hard rule | Soft rule |
| Pod will not schedule | Pod *may* schedule |
| Enforced strictly | Best-effort |
| Can block scaling | Allows overcommit |

**Result:**
- Kubernetes *tries* to spread pods
- But will co-locate if no alternative exists

---

## Part 4 – Backend API (Node Affinity)

### 1. On which nodes are backend pods scheduled? Why?

Backend pods are scheduled on **worker-node-2**.

**Reason:**
- `requiredDuringSchedulingIgnoredDuringExecution` enforces `tier=backend`
- Only worker-node-2 matches
- SSD preference is ignored because it is not available

Kubernetes always satisfies **required rules before preferences**.

---

### 2. Difference between `required` and `preferred` node affinity?

| Required | Preferred |
|---|---|
| Mandatory | Optional |
| Scheduling fails if unmet | Scheduling still succeeds |
| Used for isolation | Used for optimization |

**Rule of thumb:**  
> *Required defines correctness. Preferred defines performance.*

---

### 3. Can backend pods communicate with Postgres and Redis?

Yes.

**Proof:**
- DNS resolution succeeds:
  - `postgres.ecommerce.svc.cluster.local`
  - `redis.ecommerce.svc.cluster.local`
- ClusterIP services provide stable virtual IPs
- Kubernetes DNS (CoreDNS) handles service discovery

---

## Part 5 – Frontend

### 1. Where are frontend pods scheduled? Why?

All frontend pods run on **worker-node-1**.

**Reason:**
- Node selector enforces `tier=frontend`
- Node tolerates `workload=frontend`
- No other node qualifies

---

### 2. What happens if you scale to 10 replicas on a single node?

Pods eventually become **Pending**.

**Why:**
- Node CPU / memory limits are reached
- Scheduler cannot overcommit requested resources

---

### 3. How does NodePort distribute traffic?

- NodePort forwards traffic to the ClusterIP
- `kube-proxy` load-balances requests
- Requests are distributed across all healthy pods

---

### 4. Does browser access work via `NODE_IP:30080`?

Yes.

**Reason:**
- NodePort exposes the service on every node IP
- Traffic is routed internally to frontend pods

---

## Part 6 – Static Pods

### 1. What happens when you delete a static pod?

The pod is **recreated automatically**.

**Why:**
- Static pods are managed by the kubelet
- The kubelet continuously watches the manifest directory

---

### 2. How do you actually remove a static pod?

Delete the manifest file from the node:

```bash
sudo rm /etc/kubernetes/manifests/monitoring-agent.yaml

# ANSWERS.md
## Kubernetes E-Commerce Platform – Scheduling & Architecture Answers

---

## Part 2 – PostgreSQL

### 1. On which node did the postgres pod get scheduled? Why?

The PostgreSQL pod was scheduled on **worker-node-2**.

**Reason:**
- The pod uses a `nodeSelector` targeting `tier=backend`
- The node is tainted with `workload=backend:NoSchedule`
- The pod explicitly tolerates this taint

Kubernetes had **only one valid node** that satisfied *all* scheduling constraints.

---

### 2. What happens if you remove the toleration?

The pod remains in **Pending** state.

**Why:**
- `worker-node-2` is tainted with `workload=backend:NoSchedule`
- Without a toleration, the scheduler is forbidden from placing the pod there

This demonstrates how taints provide **hard isolation guarantees**.

---

### 3. Can you access PostgreSQL from outside the cluster?

No.

**Reason:**
- PostgreSQL is exposed using a **ClusterIP** service
- ClusterIP services are only reachable **inside the cluster network**

This is intentional and aligns with **security best practices**.

---

## Part 3 – Redis (Affinity & Anti-Affinity)

### 1. Are the Redis pods running on different nodes? Why?

Yes.

**Reason:**
- Pod anti-affinity is configured with  
  `requiredDuringSchedulingIgnoredDuringExecution`
- Redis pods are forbidden from sharing the same hostname
- Kubernetes enforces this rule strictly at scheduling time

---

### 2. What happens if you scale Redis to 3 replicas with only 2 worker nodes?

The third pod remains **Pending**.

**Why:**
- Required pod anti-affinity cannot be satisfied
- Kubernetes will not violate a *required* rule even if resources are available

This is a **safety-over-availability tradeoff**.

---

### 3. What changes when using `preferredDuringSchedulingIgnoredDuringExecution`?

**Difference:**

| Required | Preferred |
|---|---|
| Hard rule | Soft rule |
| Pod will not schedule | Pod *may* schedule |
| Enforced strictly | Best-effort |
| Can block scaling | Allows overcommit |

**Result:**
- Kubernetes *tries* to spread pods
- But will co-locate if no alternative exists

---

## Part 4 – Backend API (Node Affinity)

### 1. On which nodes are backend pods scheduled? Why?

Backend pods are scheduled on **worker-node-2**.

**Reason:**
- `requiredDuringSchedulingIgnoredDuringExecution` enforces `tier=backend`
- Only worker-node-2 matches
- SSD preference is ignored because it is not available

Kubernetes always satisfies **required rules before preferences**.

---

### 2. Difference between `required` and `preferred` node affinity?

| Required | Preferred |
|---|---|
| Mandatory | Optional |
| Scheduling fails if unmet | Scheduling still succeeds |
| Used for isolation | Used for optimization |

**Rule of thumb:**  
> *Required defines correctness. Preferred defines performance.*

---

### 3. Can backend pods communicate with Postgres and Redis?

Yes.

**Proof:**
- DNS resolution succeeds:
  - `postgres.ecommerce.svc.cluster.local`
  - `redis.ecommerce.svc.cluster.local`
- ClusterIP services provide stable virtual IPs
- Kubernetes DNS (CoreDNS) handles service discovery

---

## Part 5 – Frontend

### 1. Where are frontend pods scheduled? Why?

All frontend pods run on **worker-node-1**.

**Reason:**
- Node selector enforces `tier=frontend`
- Node tolerates `workload=frontend`
- No other node qualifies

---

### 2. What happens if you scale to 10 replicas on a single node?

Pods eventually become **Pending**.

**Why:**
- Node CPU / memory limits are reached
- Scheduler cannot overcommit requested resources

---

### 3. How does NodePort distribute traffic?

- NodePort forwards traffic to the ClusterIP
- `kube-proxy` load-balances requests
- Requests are distributed across all healthy pods

---

### 4. Does browser access work via `NODE_IP:30080`?

Yes.

**Reason:**
- NodePort exposes the service on every node IP
- Traffic is routed internally to frontend pods

---

## Part 6 – Static Pods

### 1. What happens when you delete a static pod?

The pod is **recreated automatically**.

**Why:**
- Static pods are managed by the kubelet
- The kubelet continuously watches the manifest directory

---

### 2. How do you actually remove a static pod?

Delete the manifest file from the node:

```bash
sudo rm /etc/kubernetes/manifests/monitoring-agent.yaml
