#!/bin/bash

set -euo pipefail

die() {
    echo "$1" 1>&2
    exit 1
}

# Check if buf is installed, install if not
if ! command -v buf >/dev/null 2>&1; then
    echo "buf is not installed. Attempting to install..."

    OS=$(uname -s)
    if [ "$OS" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
        brew install buf
    else
        # Fallback to manual download to local bin
        echo "Installing buf locally..."
        mkdir -p bin
        BUF_URL="https://github.com/bufbuild/buf/releases/latest/download/buf-$(uname -s)-$(uname -m)"
        curl -sSL "$BUF_URL" -o "bin/buf"
        chmod +x "bin/buf"
        export PATH="$PWD/bin:$PATH"
    fi

    if ! command -v buf >/dev/null 2>&1; then
        die "Failed to install buf. Please install it manually from https://buf.build/docs/installation"
    fi

    echo "buf installed successfully."
fi

SKIP_BREAKING=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --skip-breaking) SKIP_BREAKING=true ;;
        *) die "Unknown parameter passed: $1" ;;
    esac
    shift
done

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
cd "$ROOT_DIR" || die "Failed to cd into repo root"

echo "Formatting proto files with buf..."
buf format -w || die "Formatting failed."

echo "Linting proto files with buf..."
buf lint || die "Linting failed."

if [ "$SKIP_BREAKING" = false ]; then
    echo "Checking for breaking changes..."
    buf breaking --against .git#branch=main || die "Breaking changes detected."
else
    echo "Skipping breaking changes check due to --skip-breaking flag."
fi

echo "Generating code from proto..."
buf generate || die "Generation failed."

echo "Proto pipeline completed successfully."