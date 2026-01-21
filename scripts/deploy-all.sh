#!/usr/bin/env bash
set -e

NAMESPACE="ecommerce"

echo "[+] Creating namespace"
kubectl apply -f manifests/namespace.yaml

echo "[+] Deploying PostgreSQL"
kubectl apply -f manifests/postgres/

echo "[+] Deploying Redis"
kubectl apply -f manifests/redis/

echo "[+] Deploying Backend"
kubectl apply -f manifests/backend/

echo "[+] Deploying Frontend"
kubectl apply -f manifests/frontend/

echo "[+] Deploying Monitoring"
kubectl apply -f manifests/monitoring/

echo "[✓] All components deployed successfully"
