#!/usr/bin/env bash
#
# Build the Lambda layer payload. Run this before `terraform apply`.
#
# Lambda unpacks a layer zip into /opt and puts /opt/python on sys.path, so
# the packages must sit under a top-level `python/` directory. That is the
# only thing that makes a zip a valid Python layer.
#
# The --python-platform/--python-version/--only-binary trio matters just as
# much: without them uv resolves wheels for *this* machine. `requests` is
# pure Python, but its dependency charset-normalizer ships a C extension, so
# a layer built on macOS imports fine locally and fails inside Lambda.
#
# --target installs into a plain directory rather than a site-packages, so
# this build neither needs nor disturbs a virtualenv.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
TARGET_DIR="${BUILD_DIR}/python"

# Start clean so removing a dependency from requirements.txt actually
# removes it from the layer.
rm -rf "${BUILD_DIR}"
mkdir -p "${TARGET_DIR}"

uv pip install \
  --requirement "${SCRIPT_DIR}/requirements.txt" \
  --target "${TARGET_DIR}" \
  --python-platform x86_64-manylinux2014 \
  --python-version 3.13 \
  --only-binary=:all:

echo
echo "Layer payload built at ${TARGET_DIR}"
du -sh "${BUILD_DIR}"
