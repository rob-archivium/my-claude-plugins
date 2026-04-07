#!/usr/bin/env bash
# Auto-download and exec ripvec-mcp for the current platform.
#
# Called as the MCP server command — downloads the binary on first use,
# caches it in the plugin's bin/ directory, then exec's into it so
# stdin/stdout pass through for the MCP stdio protocol.
#
# Version is pinned here. When the plugin updates from the marketplace,
# this version bumps and the next session auto-downloads the new binary.

set -euo pipefail

RIPVEC_VERSION="0.11.0"
REPO="fnordpig/ripvec"

# Resolve plugin root (handles both ${CLAUDE_PLUGIN_ROOT} and script-relative)
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
	BIN_DIR="${CLAUDE_PLUGIN_ROOT}/bin"
else
	BIN_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

BINARY="${BIN_DIR}/ripvec-mcp"
VERSION_FILE="${BIN_DIR}/.version"

# Detect platform
OS="$(uname -s)"
ARCH="$(uname -m)"

case "${OS}-${ARCH}" in
Darwin-arm64) TARGET="aarch64-apple-darwin" ;;
Darwin-x86_64) TARGET="aarch64-apple-darwin" ;; # Rosetta can run ARM
Linux-x86_64) TARGET="x86_64-unknown-linux-gnu" ;;
Linux-aarch64) TARGET="aarch64-unknown-linux-gnu" ;;
*)
	echo "Unsupported platform: ${OS}-${ARCH}" >&2
	echo "Install manually: cargo install ripvec-mcp" >&2
	exit 1
	;;
esac

# Auto-detect CUDA: if nvidia-smi exists, the CUDA runtime is installed.
# Can be overridden: RIPVEC_CUDA=0 to force CPU, RIPVEC_CUDA=1 to force CUDA.
if [[ "$OS" == "Linux" ]]; then
	if [[ "${RIPVEC_CUDA:-auto}" == "auto" ]]; then
		if command -v nvidia-smi &>/dev/null; then
			TARGET="${TARGET}-cuda"
		fi
	elif [[ "${RIPVEC_CUDA:-}" == "1" ]]; then
		TARGET="${TARGET}-cuda"
	fi
fi

EXPECTED="${RIPVEC_VERSION}:${TARGET}"

# Fast path: binary exists, version+target match → exec immediately
if [[ -x "$BINARY" ]] && [[ -f "$VERSION_FILE" ]] && [[ "$(cat "$VERSION_FILE")" == "$EXPECTED" ]]; then
	exec "$BINARY" "$@"
fi

ARCHIVE="ripvec-v${RIPVEC_VERSION}-${TARGET}.tar.gz"
URL="https://github.com/${REPO}/releases/download/v${RIPVEC_VERSION}/${ARCHIVE}"

echo "ripvec-mcp v${RIPVEC_VERSION} not found — downloading for ${TARGET}..." >&2

# Download and extract
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

if command -v curl &>/dev/null; then
	curl -fsSL "$URL" -o "${TMPDIR}/${ARCHIVE}"
elif command -v wget &>/dev/null; then
	wget -q "$URL" -O "${TMPDIR}/${ARCHIVE}"
else
	echo "Neither curl nor wget found. Install manually: cargo install ripvec-mcp" >&2
	exit 1
fi

tar xzf "${TMPDIR}/${ARCHIVE}" -C "$TMPDIR"

# Extract binaries from the archive (archive contains ripvec-v{version}-{target}/)
EXTRACT_DIR="${TMPDIR}/ripvec-v${RIPVEC_VERSION}-${TARGET}"

# Install ripvec-mcp (required) and ripvec CLI (optional, nice to have)
cp "${EXTRACT_DIR}/ripvec-mcp" "$BINARY"
chmod +x "$BINARY"

if [[ -f "${EXTRACT_DIR}/ripvec" ]]; then
	cp "${EXTRACT_DIR}/ripvec" "${BIN_DIR}/ripvec"
	chmod +x "${BIN_DIR}/ripvec"
fi

# Record version for fast-path check
echo "${RIPVEC_VERSION}:${TARGET}" >"$VERSION_FILE"

echo "ripvec-mcp v${RIPVEC_VERSION} installed to ${BIN_DIR}" >&2

# Exec into the binary — replaces this shell process
exec "$BINARY" "$@"
