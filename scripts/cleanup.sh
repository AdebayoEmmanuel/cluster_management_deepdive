#!/usr/bin/env bash
set -e

NAMESPACE="ecommerce"

echo "[!] Deleting entire namespace: $NAMESPACE"
kubectl delete namespace $NAMESPACE --ignore-not-found

echo "[✓] Cleanup completed"
