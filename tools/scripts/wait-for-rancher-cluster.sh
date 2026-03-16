#!/usr/bin/env bash

set -euo pipefail

: "${RANCHER_URL:?RANCHER_URL is required}"
: "${RANCHER_TOKEN:?RANCHER_TOKEN is required}"
: "${PROVISIONING_CLUSTER_ID:?PROVISIONING_CLUSTER_ID is required}"
: "${MANAGEMENT_CLUSTER_ID:?MANAGEMENT_CLUSTER_ID is required}"

TIMEOUT_DURATION="${TIMEOUT_DURATION:-1200s}"
RANCHER_INSECURE="${RANCHER_INSECURE:-false}"

case "${TIMEOUT_DURATION}" in
  *m) TIMEOUT_SECONDS=$(( ${TIMEOUT_DURATION%m} * 60 )) ;;
  *s) TIMEOUT_SECONDS=${TIMEOUT_DURATION%s} ;;
  *) TIMEOUT_SECONDS=${TIMEOUT_DURATION} ;;
esac

curl_args=(--silent --show-error --fail --connect-timeout 10 --max-time 30)
if [[ "${RANCHER_INSECURE}" == "true" ]]; then
  curl_args+=(-k)
fi

deadline=$((SECONDS + TIMEOUT_SECONDS))

while (( SECONDS < deadline )); do
  if ! provisioning_payload="$(curl "${curl_args[@]}" \
    -H "Authorization: Bearer ${RANCHER_TOKEN}" \
    "${RANCHER_URL}/v1/provisioning.cattle.io.clusters/${PROVISIONING_CLUSTER_ID}")"; then
    echo "Provisioning API endpoint not ready yet"
    sleep 15
    continue
  fi

  if ! management_payload="$(curl "${curl_args[@]}" \
    -H "Authorization: Bearer ${RANCHER_TOKEN}" \
    "${RANCHER_URL}/v3/clusters/${MANAGEMENT_CLUSTER_ID}")"; then
    echo "Management API endpoint not ready yet"
    sleep 15
    continue
  fi

  if PROVISIONING_PAYLOAD="${provisioning_payload}" MANAGEMENT_PAYLOAD="${management_payload}" python3 - <<'PY'
import json
import os
import sys

provisioning = json.loads(os.environ["PROVISIONING_PAYLOAD"])
management = json.loads(os.environ["MANAGEMENT_PAYLOAD"])

conditions = provisioning.get("status", {}).get("conditions", [])
ready = next((item.get("status", "False") for item in conditions if item.get("type") == "Ready"), "False")
connected = next((item.get("status", "False") for item in conditions if item.get("type") == "Connected"), "False")
state = management.get("state", "")

if ready == "True" and connected == "True" and state == "active":
    raise SystemExit(0)

print(f"provisioning_ready={ready} provisioning_connected={connected} management_state={state}")
raise SystemExit(1)
PY
  then
    echo "Downstream Rancher cluster is ready"
    exit 0
  fi

  sleep 15
done

echo "Timed out waiting for downstream cluster readiness"
exit 1
