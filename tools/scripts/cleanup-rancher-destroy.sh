#!/usr/bin/env bash

set -euo pipefail

: "${KUBECONFIG_PATH:?KUBECONFIG_PATH is required}"

RANCHER_NAMESPACE="${RANCHER_NAMESPACE:-cattle-system}"

delete_matching_resources() {
  local resource_type="$1"

  while IFS= read -r resource_name; do
    [[ -z "${resource_name}" ]] && continue
    kubectl --kubeconfig "${KUBECONFIG_PATH}" delete "${resource_name}" --ignore-not-found >/dev/null 2>&1 || true
  done < <(
    kubectl --kubeconfig "${KUBECONFIG_PATH}" get "${resource_type}" -o name 2>/dev/null \
      | grep 'rancher' || true
  )
}

echo "Best-effort Rancher cleanup before destroy"

delete_matching_resources validatingwebhookconfiguration
delete_matching_resources mutatingwebhookconfiguration

kubectl --kubeconfig "${KUBECONFIG_PATH}" -n "${RANCHER_NAMESPACE}" delete secret rancher-webhook-ca --ignore-not-found >/dev/null 2>&1 || true
kubectl --kubeconfig "${KUBECONFIG_PATH}" patch namespace "${RANCHER_NAMESPACE}" --type=merge \
  -p '{"metadata":{"finalizers":[]}}' >/dev/null 2>&1 || true
