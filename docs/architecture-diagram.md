# Architecture Diagram – Kubernetes E-Commerce Platform

This document describes the logical and physical architecture of the Kubernetes-based e-commerce platform, including workload placement, scheduling constraints, and service connectivity.

---

## High-Level Architecture

```mermaid
flowchart TB
    subgraph Cluster["Kubernetes Cluster"]
        direction TB

        subgraph CP["Control Plane"]
            API["kube-apiserver"]
            SCH["kube-scheduler"]
            CM["controller-manager"]
            ETCD["etcd"]
        end

        subgraph W1["worker-node-1\n(frontend | ssd)\nTaint: workload=frontend"]
            FE1["Frontend Pod"]
            FE2["Frontend Pod"]
            FE3["Frontend Pod"]
            FE4["Frontend Pod"]
            REDIS1["Redis Pod"]
            TEST["Test Pod (curl)"]
            MON["Static Pod: Monitoring Agent"]
        end

        subgraph W2["worker-node-2\n(backend | hdd)\nTaint: workload=backend"]
            BE1["Backend Pod"]
            BE2["Backend Pod"]
            BE3["Backend Pod"]
            PG["Postgres Pod"]
            REDIS2["Redis Pod"]
        end

        FE_SVC["Frontend Service\n(NodePort :30080)"]
        BE_SVC["Backend Service\n(ClusterIP :8080)"]
        PG_SVC["Postgres Service\n(ClusterIP :5432)"]
        REDIS_SVC["Redis Service\n(ClusterIP :6379)"]
    end

    %% Traffic Flow
    USER["External User"] --> FE_SVC
    FE_SVC --> FE1
    FE_SVC --> FE2
    FE_SVC --> FE3
    FE_SVC --> FE4

    FE1 --> BE_SVC
    FE2 --> BE_SVC
    FE3 --> BE_SVC
    FE4 --> BE_SVC

    BE_SVC --> BE1
    BE_SVC --> BE2
    BE_SVC --> BE3

    BE1 --> PG_SVC
    BE2 --> PG_SVC
    BE3 --> PG_SVC

    BE1 --> REDIS_SVC
    BE2 --> REDIS_SVC
    BE3 --> REDIS_SVC
