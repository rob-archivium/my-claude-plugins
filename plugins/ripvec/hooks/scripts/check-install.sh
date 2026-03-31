#!/usr/bin/env bash
# Verify ripvec-mcp is in PATH. Print install instructions if missing.

if ! command -v ripvec-mcp &>/dev/null; then
	echo "ripvec-mcp not found in PATH."
	echo ""
	echo "Install with:"
	echo "  cargo install --git https://github.com/fnordpig/ripvec ripvec-mcp"
	echo ""
	echo "Requires Rust toolchain: https://rustup.rs"
	exit 1
fi

VERSION=$(ripvec-mcp --version 2>/dev/null || echo "")
echo "ripvec-mcp${VERSION:+ $VERSION} ready."
