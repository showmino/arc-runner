# The runner image of showmino's kube-runners (actions-runner-controller in
# k3s). It must stay FROM actions-runner: containerMode.dind copies
# /home/runner/externals from it.
FROM ghcr.io/actions/actions-runner:2.338.2

# renovate: datasource=github-releases depName=opentofu/opentofu
ARG TOFU_VERSION=1.13.8
ARG TOFU_SHA256=de3e77484cecd9c67494725cb4f9b1bb73c863462486d9a54f44efe49f2e5a63
# renovate: datasource=github-releases depName=hashicorp/terraform
ARG TERRAFORM_VERSION=1.17.1
ARG TERRAFORM_SHA256=4638628058e71a55212b1c563712eac03b902128f40740f3dc8174df12135061
# renovate: datasource=github-releases depName=Azure/bicep
ARG BICEP_VERSION=0.48.1
ARG BICEP_SHA256=b09ec25a9d376c1f8e33ede6ed22b587f915ad68488d5db77a6f9541748c7f6e
# renovate: datasource=github-releases depName=Azure/azure-cli extractVersion=^azure-cli-(?<version>.+)$
ARG AZURE_CLI_VERSION=2.92.0

# Kept in the image so arc-runner-test can check them.
ENV TOFU_VERSION=${TOFU_VERSION} TERRAFORM_VERSION=${TERRAFORM_VERSION} \
    BICEP_VERSION=${BICEP_VERSION} AZURE_CLI_VERSION=${AZURE_CLI_VERSION}

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl gnupg unzip make jq \
 && install -d -m 0755 /etc/apt/keyrings \
 && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg \
 && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(. /etc/os-release && echo "$VERSION_CODENAME") main" > /etc/apt/sources.list.d/azure-cli.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends "azure-cli=${AZURE_CLI_VERSION}-1~$(. /etc/os-release && echo "$VERSION_CODENAME")" \
 && rm -rf /var/lib/apt/lists/*

RUN cd /tmp \
 && curl -fsSLo tofu.deb "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_amd64.deb" \
 && echo "${TOFU_SHA256}  tofu.deb" | sha256sum -c - \
 && dpkg -i tofu.deb && rm tofu.deb \
 && curl -fsSLo terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
 && echo "${TERRAFORM_SHA256}  terraform.zip" | sha256sum -c - \
 && unzip -q terraform.zip terraform -d /usr/local/bin && rm terraform.zip \
 && curl -fsSLo /usr/local/bin/bicep "https://github.com/Azure/bicep/releases/download/v${BICEP_VERSION}/bicep-linux-x64" \
 && echo "${BICEP_SHA256}  /usr/local/bin/bicep" | sha256sum -c - \
 && chmod 0755 /usr/local/bin/bicep

USER runner
# 'az bicep' uses the Bicep above instead of downloading its own copy.
RUN az config set bicep.use_binary_from_path=true --only-show-errors \
 && az config set bicep.check_version=false --only-show-errors

COPY --chmod=0755 test.sh /usr/local/bin/arc-runner-test
