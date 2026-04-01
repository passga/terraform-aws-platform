#!/usr/bin/env bash
set -euo pipefail

: "${AWS_REGION:?AWS_REGION is required}"
: "${CLUSTER_TAG_KEY:?CLUSTER_TAG_KEY is required}"
: "${CLUSTER_TAG_VALUE:?CLUSTER_TAG_VALUE is required}"
: "${COMPONENT_TAG_KEY:?COMPONENT_TAG_KEY is required}"
: "${COMPONENT_TAG_VALUE:?COMPONENT_TAG_VALUE is required}"
: "${MANAGED_TAG_KEY:?MANAGED_TAG_KEY is required}"
: "${MANAGED_TAG_VALUE:?MANAGED_TAG_VALUE is required}"
: "${HTTP_ENDPOINT:?HTTP_ENDPOINT is required}"
: "${HTTP_TOKENS:?HTTP_TOKENS is required}"
: "${HTTP_PUT_RESPONSE_HOP_LIMIT:?HTTP_PUT_RESPONSE_HOP_LIMIT is required}"

find_instances() {
  aws ec2 describe-instances \
    --region "${AWS_REGION}" \
    --filters \
      "Name=tag:${CLUSTER_TAG_KEY},Values=${CLUSTER_TAG_VALUE}" \
      "Name=tag:${COMPONENT_TAG_KEY},Values=${COMPONENT_TAG_VALUE}" \
      "Name=tag:${MANAGED_TAG_KEY},Values=${MANAGED_TAG_VALUE}" \
      "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text
}

wait_for_instances() {
  local attempts=30
  local sleep_seconds=10
  local instance_ids=""

  for ((i = 1; i <= attempts; i++)); do
    instance_ids="$(find_instances)"
    if [[ -n "${instance_ids}" && "${instance_ids}" != "None" ]]; then
      printf '%s\n' "${instance_ids}"
      return 0
    fi
    sleep "${sleep_seconds}"
  done

  echo "No downstream cluster EC2 instances found for ${CLUSTER_TAG_KEY}=${CLUSTER_TAG_VALUE}" >&2
  return 1
}

metadata_options() {
  local instance_id="$1"

  aws ec2 describe-instances \
    --region "${AWS_REGION}" \
    --instance-ids "${instance_id}" \
    --query 'Reservations[0].Instances[0].MetadataOptions.[HttpEndpoint,HttpTokens,HttpPutResponseHopLimit,State]' \
    --output text
}

metadata_options_match() {
  local current="$1"
  local current_endpoint=""
  local current_tokens=""
  local current_hop_limit=""
  local current_state=""

  read -r current_endpoint current_tokens current_hop_limit current_state <<<"${current}"

  [[ "${current_endpoint}" == "${HTTP_ENDPOINT}" &&
    "${current_tokens}" == "${HTTP_TOKENS}" &&
    "${current_hop_limit}" == "${HTTP_PUT_RESPONSE_HOP_LIMIT}" &&
    "${current_state}" == "applied" ]]
}

wait_for_metadata_options() {
  local instance_id="$1"
  local attempts=30
  local sleep_seconds=5
  local current=""

  for ((i = 1; i <= attempts; i++)); do
    current="$(metadata_options "${instance_id}")"
    if metadata_options_match "${current}"; then
      return 0
    fi
    sleep "${sleep_seconds}"
  done

  echo "Timed out waiting for metadata options to become applied on ${instance_id}" >&2
  echo "Last observed metadata options: ${current}" >&2
  return 1
}

instance_ids="$(wait_for_instances)"

for instance_id in ${instance_ids}; do
  current="$(metadata_options "${instance_id}")"

  if metadata_options_match "${current}"; then
    continue
  fi

  aws ec2 modify-instance-metadata-options \
    --region "${AWS_REGION}" \
    --instance-id "${instance_id}" \
    --http-endpoint "${HTTP_ENDPOINT}" \
    --http-tokens "${HTTP_TOKENS}" \
    --http-put-response-hop-limit "${HTTP_PUT_RESPONSE_HOP_LIMIT}" \
    >/dev/null

  wait_for_metadata_options "${instance_id}"
done
