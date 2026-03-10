#!/usr/bin/env bash
set -euo pipefail

IP="${1:?Usage: fetch-kubeconfig.sh <PUBLIC_IP> [OUT_PATH]}"
OUT="${2:-kube/k3s.yaml}"

mkdir -p "$(dirname "$OUT")"

echo "Fetching kubeconfig from ubuntu@${IP} -> ${OUT}"
scp -i ~/.ssh/rancher-poc-key.pem -o StrictHostKeyChecking=no "ubuntu@${IP}:/home/ubuntu/.kube/config" "$OUT"

# Patch 127.0.0.1 -> public ip
sed -i "s/127.0.0.1/${IP}/g" "$OUT"

echo "KUBECONFIG ready: ${OUT}"