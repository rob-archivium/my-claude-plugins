#!/usr/bin/env bash
# Auto-download and exec ripvec-mcp for the current platform.
#
# Called as the MCP server command — downloads the latest release binary
# on first use, caches it in the plugin's bin/ directory, then exec's
# into it so stdin/stdout pass through for the MCP stdio protocol.
#
# Checks for new releases once per day (cached in .last-check).

set -euo pipefail

REPO="fnordpig/ripvec"
CHECK_INTERVAL=86400 # 1 day in seconds

# Resolve plugin root (handles both ${CLAUDE_PLUGIN_ROOT} and script-relative)
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
	BIN_DIR="${CLAUDE_PLUGIN_ROOT}/bin"
else
	BIN_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

BINARY="${BIN_DIR}/ripvec-mcp"
VERSION_FILE="${BIN_DIR}/.version"
LAST_CHECK_FILE="${BIN_DIR}/.last-check"

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
# Override: RIPVEC_CUDA=0 to force CPU, RIPVEC_CUDA=1 to force CUDA.
if [[ "$OS" == "Linux" ]]; then
	if [[ "${RIPVEC_CUDA:-auto}" == "auto" ]]; then
		if command -v nvidia-smi &>/dev/null; then
			TARGET="${TARGET}-cuda"
		fi
	elif [[ "${RIPVEC_CUDA:-}" == "1" ]]; then
		TARGET="${TARGET}-cuda"
	fi
fi

# Fetch the latest release version from GitHub.
# Cached for CHECK_INTERVAL to avoid hitting the API on every session.
get_latest_version() {
	local now
	now=$(date +%s)

	# Use cached version if check was recent
	if [[ -f "$LAST_CHECK_FILE" ]]; then
		local last_check cached_version
		last_check=$(head -1 "$LAST_CHECK_FILE")
		cached_version=$(tail -1 "$LAST_CHECK_FILE")
		if ((now - last_check < CHECK_INTERVAL)) && [[ -n "$cached_version" ]]; then
			echo "$cached_version"
			return
		fi
	fi

	# Query GitHub API for latest release tag
	local tag=""
	if command -v curl &>/dev/null; then
		tag=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null |
			grep -o '"tag_name":"[^"]*"' | head -1 | cut -d'"' -f4)
	elif command -v wget &>/dev/null; then
		tag=$(wget -qO- "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null |
			grep -o '"tag_name":"[^"]*"' | head -1 | cut -d'"' -f4)
	fi

	# Strip leading 'v' from tag (v0.12.1 → 0.12.1)
	local version="${tag#v}"

	if [[ -n "$version" ]]; then
		printf '%s\n%s\n' "$now" "$version" >"$LAST_CHECK_FILE"
		echo "$version"
	elif [[ -f "$VERSION_FILE" ]]; then
		# Can't reach GitHub — use whatever we have installed
		cut -d: -f1 "$VERSION_FILE"
	else
		echo ""
	fi
}

RIPVEC_VERSION=$(get_latest_version)

if [[ -z "$RIPVEC_VERSION" ]]; then
	echo "Cannot determine ripvec version (no network, no cached binary)." >&2
	echo "Install manually: cargo install ripvec-mcp" >&2
	exit 1
fi

EXPECTED="${RIPVEC_VERSION}:${TARGET}"

# Fast path: binary exists, version+target match → exec immediately
if [[ -x "$BINARY" ]] && [[ -f "$VERSION_FILE" ]] && [[ "$(cat "$VERSION_FILE")" == "$EXPECTED" ]]; then
	exec "$BINARY" "$@"
fi

ARCHIVE="ripvec-v${RIPVEC_VERSION}-${TARGET}.tar.gz"
URL="https://github.com/${REPO}/releases/download/v${RIPVEC_VERSION}/${ARCHIVE}"

echo "ripvec-mcp v${RIPVEC_VERSION} — downloading for ${TARGET}..." >&2

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
