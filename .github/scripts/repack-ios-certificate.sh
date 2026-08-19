#!/usr/bin/env bash

set -euo pipefail
umask 077

readonly input_path="${1:?Input PKCS#12 path is required}"
readonly output_path="${2:?Output PKCS#12 path is required}"
: "${IOS_CERTIFICATES_PASSWORD:?IOS_CERTIFICATES_PASSWORD is required}"

temporary_pem="$(mktemp "${RUNNER_TEMP:-/tmp}/ios-certificates.XXXXXX.pem")"
trap 'rm -f "$temporary_pem"' EXIT

openssl pkcs12 \
  -in "$input_path" \
  -passin env:IOS_CERTIFICATES_PASSWORD \
  -nodes \
  -out "$temporary_pem"

openssl pkcs12 \
  -export \
  -legacy \
  -in "$temporary_pem" \
  -out "$output_path" \
  -passout env:IOS_CERTIFICATES_PASSWORD
