#!/usr/bin/env bash
# Refreshes the SHA256 ARGs in the Dockerfile for the versions it pins, from
# each project's published checksums. Run it after a version bump (Renovate
# changes the version, not the hash, so its PR fails until this is run).
set -euo pipefail
cd "$(dirname "$0")"

arg() { sed -n "s/^ARG $1=//p" Dockerfile; }
set_arg() { sed -i "s/^ARG $1=.*/ARG $1=$2/" Dockerfile; echo "$1=$2"; }

tofu=$(arg TOFU_VERSION)
terraform=$(arg TERRAFORM_VERSION)
bicep=$(arg BICEP_VERSION)

set_arg TOFU_SHA256 "$(curl -fsSL "https://github.com/opentofu/opentofu/releases/download/v${tofu}/tofu_${tofu}_SHA256SUMS" | awk -v f="tofu_${tofu}_amd64.deb" '$2==f {print $1}')"
set_arg TERRAFORM_SHA256 "$(curl -fsSL "https://releases.hashicorp.com/terraform/${terraform}/terraform_${terraform}_SHA256SUMS" | awk -v f="terraform_${terraform}_linux_amd64.zip" '$2==f {print $1}')"
set_arg BICEP_SHA256 "$(curl -fsSL "https://api.github.com/repos/Azure/bicep/releases/tags/v${bicep}" | jq -r '.assets[] | select(.name=="bicep-linux-x64") | .digest | sub("^sha256:";"")')"

grep -qE '^ARG (TOFU|TERRAFORM|BICEP)_SHA256=$' Dockerfile && { echo "a checksum is empty: check the versions" >&2; exit 1; }
exit 0
