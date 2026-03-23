#!/usr/bin/env bash

set -euo pipefail

: "${KUBECONFIG_PATH:?KUBECONFIG_PATH is required}"
: "${RANCHER_HOSTNAME:?RANCHER_HOSTNAME is required}"
: "${RANCHER_URL:?RANCHER_URL is required}"
: "${RANCHER_BOOTSTRAP_PASSWORD:?RANCHER_BOOTSTRAP_PASSWORD is required}"

CERT_NAMESPACE="${CERT_NAMESPACE:-cattle-system}"
CERT_NAME="${CERT_NAME:-rancher-tls}"
TIMEOUT_DURATION="${TIMEOUT_DURATION:-20m}"
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

echo "Waiting for cert-manager Certificate ${CERT_NAMESPACE}/${CERT_NAME}..."
kubectl --kubeconfig "${KUBECONFIG_PATH}" -n "${CERT_NAMESPACE}" \
  wait --for=condition=Ready=true "certificate/${CERT_NAME}" --timeout="${TIMEOUT_SECONDS}s"

deadline=$((SECONDS + TIMEOUT_SECONDS))

while (( SECONDS < deadline )); do
  if ! kubectl --kubeconfig "${KUBECONFIG_PATH}" -n "${CERT_NAMESPACE}" get secret "${CERT_NAME}" >/dev/null 2>&1; then
    echo "TLS secret not created yet"
    sleep 10
    continue
  fi

  if ! curl "${curl_args[@]}" "${RANCHER_URL}/v3/settings/cacerts" >/dev/null; then
    echo "Trusted Rancher HTTPS endpoint not ready yet"
    sleep 10
    continue
  fi

  login_payload="$(jq -cn \
    --arg username "admin" \
    --arg password "${RANCHER_BOOTSTRAP_PASSWORD}" \
    '{username: $username, password: $password}')"
  response_file="$(mktemp)"
  http_code="$(curl "${curl_args[@]}" \
    -H "Content-Type: application/json" \
    -o "${response_file}" \
    -w "%{http_code}" \
    -X POST \
    --data "${login_payload}" \
    "${RANCHER_URL}/v3-public/localProviders/local?action=login" || true)"

  if [[ "${http_code}" == "201" ]]; then
    if jq -e '.token | select(type == "string" and length > 0)' "${response_file}" >/dev/null; then
      rm -f "${response_file}"
      echo "Rancher API and bootstrap login are ready"
      exit 0
    fi
  fi

  rm -f "${response_file}"
  echo "Rancher bootstrap login endpoint not ready yet"
  sleep 10
done

echo "Timed out waiting for Rancher readiness"
exit 1
