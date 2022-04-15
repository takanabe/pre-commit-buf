#!/bin/bash

set -eu

OS=$(uname -s)
ARCH=$(uname -m)

BUF_VERSION=v1.3.1
BUF_CHECKSUM_FILE=sha256.txt
BUF_BINARY_NAME=buf-$OS-$ARCH
BUF_BINARY_DIR=~/.cache/pre-commit/buf
BUF_BINARY=$BUF_BINARY_DIR/$BUF_BINARY_NAME-$BUF_VERSION

BUF_SUBCOMMAND=$1
PROTO_FILES=$(echo "${@:2}" | tr ' ' ',')

# Usage:
#   curl_buf $TMP_BUF_INSTALLED_DIR TARGET_FILE
function curl_buf() {
    echo $1
    echo $2
    if ! curl --fail -L -s -o "$1/$2" "https://github.com/bufbuild/buf/releases/download/$BUF_VERSION/$2"; then
        echo "error: failed to download buf" >&2
        exit 1
    fi
}

function exec_buf() {
    case "$2" in
        "format")
            #exec "$BUF_BINARY" "$BUF_SUBCOMMAND" "--write" "--exit-code" "--path" "$PROTO_FILES"
            exec "$1" "$2" "--write" "--exit-code" "--path" "$3"
        ;;
        "lint")
            exec "$1" "$2" "--path" "$3"
        ;;
        *)
            echo "Unexpected subcommand $1 was passed."
            exit 1
        ;;
    esac
}

# check if buf already is installed or not
if [[ -x "$BUF_BINARY" ]]; then
    # echo "Run: $BUF_BINARY $BUF_SUBCOMMAND --path $PROTO_FILES"
    exec_buf "$BUF_BINARY" "$BUF_SUBCOMMAND" "$PROTO_FILES"
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
    
    exec_buf "$BUF_BINARY" "$BUF_SUBCOMMAND" "$PROTO_FILES"
else
    echo "error: buf sha mismatch" >&2
    rm -f "$BUF_BINARY"
    exit 1
fi
