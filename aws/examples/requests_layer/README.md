# Requests Layer Example

Publishes a Lambda layer containing the `requests` library, for functions to attach.

This example only *builds and publishes* the layer. For a function that consumes it, see
[`requests_lambda/`](../requests_lambda/).

## What a layer actually is

A zip that Lambda unpacks into `/opt`. For Python, `/opt/python` is already on `sys.path`, so a
layer is valid if — and only if — its packages sit under a top-level `python/` directory:

```
requests_layer.zip
└── python/
    ├── requests/
    ├── urllib3/
    ├── idna/
    ├── certifi/
    └── charset_normalizer/
```

## The build step

Terraform can zip a directory, but it cannot run `pip`. So [`build_layer.sh`](build_layer.sh)
stages the packages first and Terraform zips what it finds:

```
requirements.txt  →  build/python/   →  dist/requests_layer.zip  →  aws_lambda_layer_version
   (contract)        build_layer.sh      archive_file (Terraform)      (published to AWS)
```

The build must cross-compile. `requests` is pure Python, but its dependency
`charset-normalizer` ships a C extension, so a plain install on macOS produces a Darwin `.so`
that imports fine locally and fails inside Lambda. Hence:

```
--python-platform x86_64-manylinux2014 --python-version 3.13 --only-binary=:all:
```

Verify it worked by checking the extension's architecture:

```bash
find build/python -name "*.so"
# build/python/charset_normalizer/md.cpython-313-x86_64-linux-gnu.so
```

`x86_64-linux-gnu` is correct. Anything with `darwin` in the name will fail at import time in
Lambda.

`--target` installs into a plain directory rather than a site-packages, so the build neither
needs nor disturbs a virtualenv.

## Prerequisites

- AWS CLI with credentials configured
- Terraform >= 1.14
- [`uv`](https://docs.astral.sh/uv/) (swap in `python3 -m pip` with pip's flag spellings if you
  prefer: `--platform manylinux2014_x86_64`)

## Setup

```bash
./build_layer.sh
terraform init
terraform apply
```

> **Re-run `build_layer.sh` after editing `requirements.txt`.** If you don't, `archive_file`
> zips the stale `build/` directory, the hash is unchanged, and Terraform reports "No changes" —
> you get the old dependencies with no error anywhere. Terraform hashes the zip, not
> `requirements.txt`, so nothing in the chain can catch this for you.

## Versioning

Every `apply` that changes the zip publishes a *new layer version*; AWS never mutates an existing
one. Old versions stay until explicitly deleted, and functions pinned to them keep working.

This is why consumers look the layer up by name and take the latest version, rather than
hardcoding a version ARN that goes stale on the next publish.

## Cleaning up

```bash
terraform destroy
```

Destroy the consuming function in [`requests_lambda/`](../requests_lambda/) first — a layer
version cannot be deleted while a function still references it.

## Outputs

| Output              | Description                                                     |
|---------------------|-----------------------------------------------------------------|
| `layer_name`        | Name consumers look the layer up by                             |
| `layer_version_arn` | ARN of this specific published version — what a function attaches to |
| `layer_arn`         | ARN of the layer itself, without a version suffix               |
| `version`           | Version number, incremented by AWS on every publish             |
