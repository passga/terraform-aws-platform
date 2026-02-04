#!/bin/bash
set -euo pipefail

SAURON_TAG_NAME="${SAURON_TAG_NAME:-sauron:latest}"
RANCHER_PATH="${RANCHER_PATH:-$PWD/rancher/}"
TERRAFORM_PATH="${TERRAFORM_PATH:-$PWD/../../terraform/}"
HELM_CHARTS_PATH="${HELM_CHARTS_PATH:-$PWD/../../charts}"

ACTION="${1:-}"
shift || true

case "$ACTION" in
  create-infra)
    INNER_CMD='cd /opt/terraform && terraform init && terraform apply'
    ;;
  destroy-infra)
    INNER_CMD='cd /opt/terraform && terraform destroy'
    ;;
  *)
    echo "Usage: $0 {create-infra|destroy-infra}"
    exit 1
    ;;
esac

run_cmd=(
  docker run --rm -it
  -e AWS_ACCESS_KEY_ID
  -e AWS_SECRET_ACCESS_KEY
  -e AWS_SESSION_TOKEN
  -e AWS_DEFAULT_REGION=eu-west-3
  -v "${HELM_CHARTS_PATH}:/opt/file/charts"
  -v "${RANCHER_PATH}:/root/.rancher/"
  -v "${TERRAFORM_PATH}:/opt/terraform/"
  "${SAURON_TAG_NAME}"
  -c "${INNER_CMD}"
)

echo "Running command: ${run_cmd[*]}"
