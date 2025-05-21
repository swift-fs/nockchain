#!/bin/bash

RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'

PROJECT_DIR="$HOME/nockchain"

banner() {
  echo -e "${BOLD}${BLUE}"
  echo "==============================================="
  echo "        Nock Setup Utility"
  echo "==============================================="
  echo -e "${RESET}"
  echo "-----------------------------------------------"
  echo ""
}

install_stack() {
  echo -e "[*] Installing dependencies..."
  apt-get update && apt install -y sudo
  sudo apt install -y screen curl git wget make gcc build-essential jq \
    pkg-config libssl-dev libleveldb-dev clang unzip nano autoconf \
    automake htop ncdu bsdmainutils tmux lz4 iptables nvme-cli libgbm1

  echo -e "[*] Setting up Rust toolchain..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
  rustup default stable

  echo -e "[*] Cloning repository..."
  if [ -d "$PROJECT_DIR" ]; then
    cd "$PROJECT_DIR" && git pull
  else
    git clone --depth=1 https://github.com/zorp-corp/nockchain "$PROJECT_DIR"
  fi

  cd "$PROJECT_DIR" || exit 1

  # Use (total cores - 1) as default for compilation
  CORE_COUNT=$(($(nproc) - 1))
  echo -e "[*] Building with ${CORE_COUNT} cores..."

  make install-hoonc
  make -j$CORE_COUNT build-hoon-all
  make -j$CORE_COUNT build
  make -j$CORE_COUNT install-nockchain-wallet
  make -j$CORE_COUNT install-nockchain

  echo -e "[*] Adding binaries to PATH..."
  RC_FILE="$HOME/.bashrc"
  [[ "$SHELL" == *"zsh"* ]] && RC_FILE="$HOME/.zshrc"

  echo 'export PATH="$PATH:$HOME/nockchain/target/release"' >> "$RC_FILE"
  echo 'export RUST_LOG=info' >> "$RC_FILE"
  echo 'export MINIMAL_LOG_FORMAT=true' >> "$RC_FILE"
  source "$RC_FILE"

  echo -e "${GREEN}[+] All done.${RESET}"
}

generate_wallet() {
  echo -e "[*] Generating wallet..."
  if [ ! -f "$PROJECT_DIR/target/release/nockchain-wallet" ]; then
    echo -e "${RED}[-] Wallet executable not found.${RESET}"
    exit 1
  fi

  tmpfile=$(mktemp)
  "$PROJECT_DIR/target/release/nockchain-wallet" keygen 2>&1 | tr -d '\0' | tee "$tmpfile"

  if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}[+] Wallet generated!${RESET}"

    mnemonic=$(grep "wallet: memo:" "$tmpfile" | head -1 | sed -E 's/^.*wallet: memo: (.*)$/\1/')
    private_key=$(grep 'private key: base58' "$tmpfile" | head -1 | sed -E 's/^.*private key: base58 "(.*)".*$/\1/')
    public_key=$(grep 'public key: base58' "$tmpfile" | head -1 | sed -E 's/^.*public key: base58 "(.*)".*$/\1/')

    echo -e "\n${YELLOW}=== KEEP THESE CREDENTIALS SAFE ===${RESET}"
    echo -e "${BOLD}Mnemonic:${RESET}\n$mnemonic\n"
    echo -e "${BOLD}Private Key:${RESET}\n$private_key\n"
    echo -e "${BOLD}Public Key:${RESET}\n$public_key\n"
    echo -e "${YELLOW}===================================${RESET}\n"
  else
    echo -e "${RED}[-] Wallet creation failed!${RESET}"
    exit 1
  fi

  rm -f "$tmpfile"
}

launch_leader_node() {

  # Ask for mining public key
  read -p "Enter your mining public key: " mining_key

  if [ -z "$mining_key" ]; then
    echo -e "${RED}[-] Mining public key is required for leader node${RESET}"
    exit 1
  fi

  # Update Makefile with the mining key
  if [ -f "$PROJECT_DIR/Makefile" ]; then
    sed -i "s|^export MINING_PUBKEY :=.*$|export MINING_PUBKEY := $mining_key|" "$PROJECT_DIR/Makefile"
    echo -e "${GREEN}[+] Mining key updated in Makefile${RESET}"
  else
    echo -e "${RED}[-] Makefile not found${RESET}"
    exit 1
  fi

  echo -e "Starting leader node..."

  screen -S leader-node -dm bash -c "cd \"$PROJECT_DIR\" && make run-nockchain-leader"
  echo -e "${GREEN}Ctrl+A+D to detach.${RESET}"
  sleep 2
  screen -r leader-node
}

launch_follower_node() {
  echo -e "Starting follower node..."
  screen -S follower-node -dm bash -c "cd \"$PROJECT_DIR\" && make run-nockchain-follower"
  echo -e "${GREEN}Ctrl+A+D to detach.${RESET}"
  sleep 2
  screen -r follower-node
}

show_usage() {
  echo "Usage: $0 [OPTION]"
  echo ""
  echo "Options:"
  echo "  --install        Install and build Nock"
  echo "  --createwallet   Generate a new wallet"
  echo "  --startleader    Start the leader node"
  echo "  --startfollower  Start the follower node"
  echo "  --help          Show this help message"
  echo ""
  exit 1
}

# Main script logic
if [ $# -eq 0 ]; then
  show_usage
fi

case "$1" in
  --install)
    banner
    install_stack
    ;;
  --createwallet)
    banner
    generate_wallet
    ;;
  --startleader)
    banner
    launch_leader_node
    ;;
  --startfollower)
    banner
    launch_follower_node
    ;;
  --help)
    show_usage
    ;;
  *)
    echo -e "${RED}[-] Invalid option.${RESET}"
    show_usage
    ;;
esac