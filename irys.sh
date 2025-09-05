#!/bin/bash

CONFIG="$HOME/.irys_env"

# Load config if exists
if [ -f "$CONFIG" ]; then
  source "$CONFIG"
fi

install_deps() {
  echo "🔧 Installing dependencies..."
  sudo apt-get update && sudo apt-get upgrade -y
  sudo apt install -y curl git wget lz4 jq make gcc nano tmux htop unzip ufw \
    build-essential cmake pkg-config libssl-dev

  echo "🔧 Installing Node.js 20..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs

  echo "🔧 Installing Irys CLI..."
  sudo npm install -g @irys/cli

  echo "✅ Installation complete."
}

fund_wallet() {
  read -p "Enter amount in wei: " AMOUNT
  irys fund "$AMOUNT" \
    -t "$IRYS_TOKEN" -n "$IRYS_NETWORK" \
    -w "$IRYS_PRIVATE_KEY" \
    --provider-url "$IRYS_RPC_URL"
}

check_balance() {
  irys balance "$IRYS_WALLET" \
    -t "$IRYS_TOKEN" -n "$IRYS_NETWORK" \
    --provider-url "$IRYS_RPC_URL"
}

upload_file() {
  read -p "Enter file path: " FILE
  read -p "Enter MIME type (e.g., image/png): " MIME
  irys upload "$FILE" \
    -t "$IRYS_TOKEN" -n "$IRYS_NETWORK" \
    -w "$IRYS_PRIVATE_KEY" \
    --tags Content-Type "$MIME" \
    --provider-url "$IRYS_RPC_URL"
}

upload_folder() {
  read -p "Enter folder path: " FOLDER
  irys upload-dir "$FOLDER" \
    -t "$IRYS_TOKEN" -n "$IRYS_NETWORK" \
    -w "$IRYS_PRIVATE_KEY" \
    --provider-url "$IRYS_RPC_URL"
}

check_price() {
  read -p "Enter file size in bytes: " BYTES
  irys price "$BYTES" \
    -t "$IRYS_TOKEN" -n "$IRYS_NETWORK" \
    --provider-url "$IRYS_RPC_URL"
}

case "$1" in
  install) install_deps ;;
  fund) fund_wallet ;;
  balance) check_balance ;;
  upload) upload_file ;;
  upload-dir) upload_folder ;;
  price) check_price ;;
  *)
    echo "Usage:"
    echo "  $0 install      # install dependencies + irys cli"
    echo "  $0 fund         # fund your wallet (asks amount)"
    echo "  $0 balance      # check wallet balance"
    echo "  $0 upload       # upload a file (asks file + mime)"
    echo "  $0 upload-dir   # upload a folder"
    echo "  $0 price        # check price for file size"
    ;;
esac
