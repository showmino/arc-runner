#!/usr/bin/env bash
# Checks the image has the tools and versions it promises. Run in CI after the
# build: docker run --rm <image> arc-runner-test
set -euo pipefail

fail=0
check() {
  local name=$1 want=$2 got
  got=$("${@:3}" 2>&1) || { echo "FAIL $name: $got"; fail=1; return; }
  got=${got%%$'\n'*}
  if [[ $got == *"$want"* ]]; then echo "ok   $name: $got"; else echo "FAIL $name: want $want, got $got"; fail=1; fi
}

check tofu "${TOFU_VERSION:-}" tofu version
check terraform "${TERRAFORM_VERSION:-}" terraform version
check bicep "${BICEP_VERSION:-}" bicep --version
check az "${AZURE_CLI_VERSION:-}" bash -c "az version --query '\"azure-cli\"' -o tsv"
check "az bicep" "${BICEP_VERSION:-}" az bicep version --only-show-errors
check unzip "UnZip" unzip -v
check make "Make" make --version

exit $fail
