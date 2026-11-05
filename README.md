# arc-runner

The runner image of showmino's `kube-runners`, the
[actions-runner-controller](https://github.com/actions/actions-runner-controller)
scale set in k3s. It is `ghcr.io/actions/actions-runner` with the tools the
Forge infrastructure workflow needs:

| Tool | Pinned in |
| --- | --- |
| Azure CLI (`az`, with `az bicep` using the Bicep below) | `AZURE_CLI_VERSION` |
| Bicep | `BICEP_VERSION`, `BICEP_SHA256` |
| OpenTofu | `TOFU_VERSION`, `TOFU_SHA256` |
| Terraform | `TERRAFORM_VERSION`, `TERRAFORM_SHA256` |
| unzip, make, jq | the Ubuntu packages |

Every download is checked against the SHA256 in the `Dockerfile`.

## Changing a version

Edit the `ARG ..._VERSION` in the `Dockerfile` (Renovate opens these pull
requests), then run `./update-checksums.sh` and commit the result. CI fails
while a checksum does not match its version.

## Releases

CI builds and tests every pull request (`arc-runner-test` checks each tool's
version). A merge to `main` pushes `ghcr.io/showmino/arc-runner:sha-<commit>`;
a tag `vX.Y.Z` also pushes `:vX.Y.Z`. The scale set in `showmino/kubernetes`
(`apps/helm/action-runner-set/production/app.yaml`) pins a `vX.Y.Z` tag.

The image must stay `FROM ghcr.io/actions/actions-runner`: the scale set's
Docker-in-Docker mode copies `/home/runner/externals` out of it.
