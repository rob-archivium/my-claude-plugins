#!/usr/bin/env bash
# Auto-download and exec ripvec-mcp for the current platform.
#
# Downloads the latest release binary on first use, caches in
# ${CLAUDE_PLUGIN_DATA}/bin/ (persists across plugin updates).
# Checks for new releases once per day.

set -euo pipefail

REPO="fnordpig/ripvec"
CHECK_INTERVAL=86400 # 1 day

# Binary cache goes in PLUGIN_DATA (survives plugin updates)
# Fall back to PLUGIN_ROOT/bin if DATA isn't available
if [[ -n "${CLAUDE_PLUGIN_DATA:-}" ]]; then
	BIN_DIR="${CLAUDE_PLUGIN_DATA}/bin"
	mkdir -p "$BIN_DIR"
elif [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
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
Darwin-x86_64) TARGET="aarch64-apple-darwin" ;;
Linux-x86_64) TARGET="x86_64-unknown-linux-gnu" ;;
Linux-aarch64) TARGET="aarch64-unknown-linux-gnu" ;;
*)
	echo "Unsupported platform: ${OS}-${ARCH}" >&2
	exit 1
	;;
esac

# Auto-detect CUDA
if [[ "$OS" == "Linux" ]]; then
	if [[ "${RIPVEC_CUDA:-auto}" == "auto" ]]; then
		command -v nvidia-smi &>/dev/null && TARGET="${TARGET}-cuda"
	elif [[ "${RIPVEC_CUDA:-}" == "1" ]]; then
		TARGET="${TARGET}-cuda"
	fi
fi

# --update: force immediate version check, bypassing cache
if [[ "${1:-}" == "--update" ]]; then
	rm -f "$LAST_CHECK_FILE"
	shift
fi

# --install-only: download binary without exec (used by hooks)
INSTALL_ONLY=false
if [[ "${1:-}" == "--install-only" ]]; then
	INSTALL_ONLY=true
	shift
fi

# Fetch latest version (cached for CHECK_INTERVAL)
get_latest_version() {
	local now
	now=$(date +%s)

	if [[ -f "$LAST_CHECK_FILE" ]]; then
		local last_check cached_version
		last_check=$(head -1 "$LAST_CHECK_FILE")
		cached_version=$(tail -1 "$LAST_CHECK_FILE")
		if ((now - last_check < CHECK_INTERVAL)) && [[ -n "$cached_version" ]]; then
			echo "$cached_version"
			return
		fi
	fi

	local tag=""
	if command -v curl &>/dev/null; then
		tag=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null |
			grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
	elif command -v wget &>/dev/null; then
		tag=$(wget -qO- "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null |
			grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
	fi

	local version="${tag#v}"
	if [[ -n "$version" ]]; then
		printf '%s\n%s\n' "$now" "$version" >"$LAST_CHECK_FILE"
		echo "$version"
	elif [[ -f "$VERSION_FILE" ]]; then
		cut -d: -f1 "$VERSION_FILE"
	else
		echo ""
	fi
}

RIPVEC_VERSION=$(get_latest_version)

if [[ -z "$RIPVEC_VERSION" ]]; then
	echo "Cannot determine ripvec version." >&2
	exit 1
fi

EXPECTED="${RIPVEC_VERSION}:${TARGET}"

# Fast path: binary exists, version+target match
if [[ -x "$BINARY" ]] && [[ -f "$VERSION_FILE" ]] && [[ "$(cat "$VERSION_FILE")" == "$EXPECTED" ]]; then
	$INSTALL_ONLY && exit 0
	exec "$BINARY" "$@"
fi

# Download
ARCHIVE="ripvec-v${RIPVEC_VERSION}-${TARGET}.tar.gz"
URL="https://github.com/${REPO}/releases/download/v${RIPVEC_VERSION}/${ARCHIVE}"

echo "ripvec-mcp v${RIPVEC_VERSION} — downloading for ${TARGET}..." >&2

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

if command -v curl &>/dev/null; then
	curl -fsSL "$URL" -o "${TMPDIR}/${ARCHIVE}"
elif command -v wget &>/dev/null; then
	wget -q "$URL" -O "${TMPDIR}/${ARCHIVE}"
else
	echo "No curl/wget. Install: cargo binstall ripvec-mcp" >&2
	exit 1
fi

tar xzf "${TMPDIR}/${ARCHIVE}" -C "$TMPDIR"
EXTRACT_DIR="${TMPDIR}/ripvec-v${RIPVEC_VERSION}-${TARGET}"

cp "${EXTRACT_DIR}/ripvec-mcp" "$BINARY"
chmod +x "$BINARY"
[[ -f "${EXTRACT_DIR}/ripvec" ]] && cp "${EXTRACT_DIR}/ripvec" "${BIN_DIR}/ripvec" && chmod +x "${BIN_DIR}/ripvec"

echo "${RIPVEC_VERSION}:${TARGET}" >"$VERSION_FILE"
echo "ripvec-mcp v${RIPVEC_VERSION} installed." >&2

$INSTALL_ONLY && exit 0
exec "$BINARY" "$@"
