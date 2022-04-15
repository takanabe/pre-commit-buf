#!/bin/bash

set -euo pipefail

OS=$(uname -s)
ARCH=$(uname -m)

BUF_VERSION=v1.3.1
BUF_CHECKSUM_FILE=sha256.txt
BUF_BINARY_NAME=buf-$OS-$ARCH
BUF_BINARY_DIR=~/.cache/pre-commit/buf
BUF_BINARY=$BUF_BINARY_DIR/$BUF_BINARY_NAME-$BUF_VERSION

# Usage:
#   curl_buf $TMP_BUF_INSTALLED_DIR TARGET_FILE
function curl_buf() {
    if ! curl --fail -L -s -o "$1/$2" "https://github.com/bufbuild/buf/releases/download/$BUF_VERSION/$2"; then
        echo "error: failed to download buf" >&2
        exit 1
    fi
}

# check if buf already is installed or not
if [[ -x "$BUF_BINARY" ]]; then
    exec "$BUF_BINARY" "$@"
fi

# Prepare directories
mkdir -p "$BUF_BINARY_DIR"
TMPDIR=$(mktemp -d)

# Download the specified version of buf release.
curl_buf $TMPDIR $BUF_CHECKSUM_FILE
curl_buf $TMPDIR $BUF_BINARY_NAME

# Retrieve check sum from downloaded the SHA256 list
BUF_CHECKSUM=$(cat $TMPDIR/$BUF_CHECKSUM_FILE | grep $BUF_BINARY_NAME | grep -v tar.gz | cut -d " " -f 1)

# Check SHA256 then install buf in $BUF_BINARY
if echo "$BUF_CHECKSUM  $TMPDIR/$BUF_BINARY_NAME" | shasum -a 256 --check --status; then
    if [[ ! -x "$BUF_BINARY" ]]; then
        mv "$TMPDIR/$BUF_BINARY_NAME" "$BUF_BINARY"
        chmod +x "$BUF_BINARY"
    fi
    
    exec "$BUF_BINARY" "$@"
else
    echo "error: buf sha mismatch" >&2
    rm -f "$BUF_BINARY"
    exit 1
fi
