#!/bin/bash
set -euo pipefail

# ==============================================================================
# irys.sh - combined installer + helper for Irys CLI
# Loads project-local .irys_env first, then $HOME/.irys_env
# Usage: ./irys.sh {install|balance|fund|upload|upload-dir|price|help}
# ==============================================================================

# Determine script dir for project-local .irys_env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load env: project-local then fallback to home
if [ -f "${SCRIPT_DIR}/.irys_env" ]; then
  # shellcheck disable=SC1090
  source "${SCRIPT_DIR}/.irys_env"
elif [ -f "$HOME/.irys_env" ]; then
  # shellcheck disable=SC1090
  source "$HOME/.irys_env"
fi

# Helper to run irys (prefer global binary, fallback to npx)
run_irys() {
  if command -v irys >/dev/null 2>&1; then
    irys "$@"
  else
    npx --yes irys "$@"
  fi
}

# Install dependencies & Irys CLI (one-shot)
install_deps() {
  echo "🔧 Installing dependencies..."
  # Only run apt-based install (assumes Debian/Ubuntu). If using macOS, install Node via brew manually.
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "apt-get not found. On macOS, run: brew install node"
    return 1
  fi

  sudo apt-get update && sudo apt-get upgrade -y
  sudo apt install -y curl git wget lz4 jq make gcc nano tmux htop unzip ufw \
    build-essential cmake pkg-config libssl-dev file

  echo "🔧 Installing Node.js 20..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs

  echo "🔧 Installing Irys CLI (global npm package)..."
  sudo npm install -g @irys/cli

  echo "✅ Installation complete."
  echo "TIP: You can also use the script's commands without global install (it will use npx)."
}

# Validate required env values (used by actions other than install)
validate_env() {
  if [ -z "${IRYS_RPC_URL-}" ] || [[ ! "${IRYS_RPC_URL}" =~ ^https?:// ]]; then
    echo "Invalid or missing IRYS_RPC_URL in .irys_env (must start with http:// or https://)."
    echo "Set IRYS_RPC_URL in ${SCRIPT_DIR}/.irys_env or $HOME/.irys_env"
    exit 1
  fi
  if [ -z "${IRYS_TOKEN-}" ]; then
    echo "IRYS_TOKEN not set in .irys_env (e.g. ethereum, irys, polygon, etc.)."
    exit 1
  fi
  if [ -z "${IRYS_PRIVATE_KEY-}" ]; then
    echo "IRYS_PRIVATE_KEY not set in .irys_env."
    exit 1
  fi
  if [ -z "${IRYS_WALLET-}" ]; then
    echo "IRYS_WALLET not set in .irys_env."
    exit 1
  fi
}

# Prepare CLI args from env:
prepare_args() {
  # CLI_NET_ARG: only set -n if IRYS_NETWORK is exactly mainnet or devnet (to avoid forcing Irys bundler mapping)
  CLI_NET_ARG=""
  if [ -n "${IRYS_NETWORK-}" ]; then
    if [ "${IRYS_NETWORK}" = "mainnet" ] || [ "${IRYS_NETWORK}" = "devnet" ]; then
      CLI_NET_ARG="-n ${IRYS_NETWORK}"
    else
      CLI_NET_ARG=""   # for custom chains like sepolia, don't pass -n
    fi
  fi

  # BUNDLER_ARG: override the uploader/bundler host if provided
  BUNDLER_ARG=""
  if [ -n "${IRYS_BUNDLER_URL-}" ]; then
    # Use -h to override upload/target host (works in Irys CLI examples)
    BUNDLER_ARG="-h ${IRYS_BUNDLER_URL}"
  fi
}

# -------------------------
# Action functions
# -------------------------
balance() {
  validate_env
  prepare_args
  echo "Loaded address: ${IRYS_WALLET}"
  run_irys balance "${IRYS_WALLET}" -t "${IRYS_TOKEN}" ${CLI_NET_ARG} ${BUNDLER_ARG} --provider-url "${IRYS_RPC_URL}"
}

fund() {
  validate_env
  prepare_args
  read -r -p "Enter amount in wei: " AMOUNT_INPUT
  AMOUNT="${AMOUNT_INPUT//[[:space:]]/}"   # trim spaces
  if [[ -z "$AMOUNT" ]]; then
    echo "Aborted: amount empty."
    return 1
  fi
  echo "Loaded address: ${IRYS_WALLET}"
  # Show human-readable approximate ETH value if decimals known (18)
  # Compute with bc if available
  if command -v bc >/dev/null 2>&1; then
    ETH_VAL=$(printf "scale=18; %s/1000000000000000000\n" "$AMOUNT" | bc -l)
    echo "Confirm: send ${AMOUNT} wei (~${ETH_VAL} ETH) to bundler?"
  else
    echo "Confirm: send ${AMOUNT} wei to bundler?"
  fi

  read -r -p "Y / N? " yn
  case "${yn}" in
    [Yy]* ) 
      run_irys fund "$AMOUNT" -t "${IRYS_TOKEN}" ${CLI_NET_ARG} ${BUNDLER_ARG} -w "${IRYS_PRIVATE_KEY}" --provider-url "${IRYS_RPC_URL}" || {
        echo "Error whilst funding."
        return 1
      }
      ;;
    *) echo "Cancelled." ; return 1 ;;
  esac
}

upload() {
  validate_env
  prepare_args
  read -r -p "Enter file path: " FILE
  FILE="${FILE/#\~/$HOME}"   # expand ~
  # If user entered relative path without slash, try relative to script dir and PWD
  if [ -z "$FILE" ]; then
    echo "No file provided."
    return 1
  fi
  if [ ! -f "$FILE" ]; then
    # try current directory
    if [ -f "${PWD}/$FILE" ]; then
      FILE="${PWD}/$FILE"
    elif [ -f "${SCRIPT_DIR}/$FILE" ]; then
      FILE="${SCRIPT_DIR}/$FILE"
    else
      echo "Error: file not found: $FILE"
      return 1
    fi
  fi

  # Auto-detect MIME
  MIME=""
  if command -v file >/dev/null 2>&1; then
    MIME=$(file --mime-type -b "$FILE" 2>/dev/null || true)
  fi
  if [ -z "${MIME}" ]; then
    read -r -p "Enter MIME type (e.g., image/png): " MIME
    MIME="${MIME//[[:space:]]/}"
    if [ -z "$MIME" ]; then
      echo "No MIME type provided. Aborting."
      return 1
    fi
  else
    echo "Detected MIME: ${MIME}"
  fi

  run_irys upload "$FILE" -t "${IRYS_TOKEN}" ${CLI_NET_ARG} ${BUNDLER_ARG} -w "${IRYS_PRIVATE_KEY}" --tags Content-Type "${MIME}" --provider-url "${IRYS_RPC_URL}" || {
    echo "Error whilst uploading file."
    return 1
  }
}

upload_dir() {
  validate_env
  prepare_args
  read -r -p "Enter folder path: " FOLDER
  FOLDER="${FOLDER/#\~/$HOME}"
  if [ -z "$FOLDER" ]; then
    echo "No folder provided."
    return 1
  fi
  if [ ! -d "$FOLDER" ]; then
    echo "Error: folder not found: $FOLDER"
    return 1
  fi
  run_irys upload-dir "$FOLDER" -t "${IRYS_TOKEN}" ${CLI_NET_ARG} ${BUNDLER_ARG} -w "${IRYS_PRIVATE_KEY}" --provider-url "${IRYS_RPC_URL}" || {
    echo "Error whilst uploading directory."
    return 1
  }
}

price() {
  validate_env
  prepare_args
  # If user provided a filename as second arg, use that to compute bytes, otherwise prompt
  if [ -n "${2-}" ] && [ -f "${2}" ]; then
    BYTES=$(stat -c%s "$2")
    echo "File size: ${BYTES} bytes"
  else
    read -r -p "Enter file size in bytes: " BYTES
  fi
  if [[ -z "$BYTES" ]]; then
    echo "No byte size provided."
    return 1
  fi
  run_irys price "$BYTES" -t "${IRYS_TOKEN}" ${CLI_NET_ARG} ${BUNDLER_ARG} --provider-url "${IRYS_RPC_URL}"
}

help_msg() {
  cat <<'EOF'
Usage: ./irys.sh <command>

Commands:
  install       Install OS deps, Node.js, and Irys CLI (apt-based systems)
  balance       Check balance (reads ~/.irys_env or project .irys_env)
  fund          Fund your Irys account (prompts for amount in wei)
  upload        Upload single file (prompts for file path; auto-detects MIME)
  upload-dir    Upload a folder (prompts for folder path)
  price         Check price for size (prompts for bytes; pass filename as second arg to auto-calc size)
  help          Show this help

Notes:
- Place your config in either ./ .irys_env (project-local) or ~/.irys_env, e.g.:
  export IRYS_PRIVATE_KEY=your_private_key_here   # no 0x
  export IRYS_RPC_URL=https://sepolia.drpc.org
  export IRYS_TOKEN=ethereum
  export IRYS_WALLET=0xYourWalletAddressHere
  # Optional to override uploader/bundler host:
  export IRYS_BUNDLER_URL=https://devnet.irys.xyz

- If IRYS_BUNDLER_URL is set it will be passed via "-h <url>" to the CLI to override default uploader host.
EOF
}

# -------------------------
# Main dispatch
# -------------------------
cmd="${1-:-help}"

case "$cmd" in
  install) install_deps ;;
  balance) balance ;;
  fund) fund ;;
  upload) upload ;;
  "upload-dir") upload_dir ;;
  price) price "${@:2}" ;;
  help|--help|-h) help_msg ;;
  *)
    echo "Unknown command: $cmd"
    help_msg
    exit 1
    ;;
esac
