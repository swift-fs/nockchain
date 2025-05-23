#!/bin/bash

# ========= Color Definitions =========
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'

# ========= Project Path =========
NCK_DIR="$HOME/nockchain"
MAX_INSTANCES=$(nproc)

# ========= Banner and Signature =========
function show_banner() {
  clear
  echo -e "${BOLD}${BLUE}"
  echo "               ╔═╗╔═╦╗─╔╦═══╦═══╦═══╦═══╗"
  echo "               ╚╗╚╝╔╣║─║║╔══╣╔═╗║╔═╗║╔═╗║"
  echo "               ─╚╗╔╝║║─║║╚══╣║─╚╣║─║║║─║║"
  echo "               ─╔╝╚╗║║─║║╔══╣║╔═╣╚═╝║║─║║"
  echo "               ╔╝╔╗╚╣╚═╝║╚══╣╚╩═║╔═╗║╚═╝║"
  echo "               ╚═╝╚═╩═══╩═══╩═══╩╝─╚╩═══╝"
  echo -e "${RESET}"
  echo "               Follow TG Channel: t.me/xuegaoz"
  echo "               My GitHub: github.com/Gzgod"
  echo "               My Twitter: @Xuegaogx"
  echo "-----------------------------------------------"
  echo -e "${CYAN}               Max CPU Cores: $MAX_INSTANCES${RESET}"
  echo ""
}

# ========= Install System Dependencies =========
function install_dependencies() {
  if ! command -v apt-get &> /dev/null; then
    echo -e "${RED}[-] This script assumes Debian/Ubuntu system (apt). Please install dependencies manually!${RESET}"
    pause_and_return
    return
  fi
  echo -e "[*] Updating system and installing dependencies..."
  apt-get update && apt-get upgrade -y && apt install -y sudo

  # Install core dependencies including the new ones for Nockchain
  sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip screen

  # Install the new required dependencies for Nockchain
  sudo apt install -y clang llvm-dev libclang-dev

  echo -e "${GREEN}[+] All dependencies installed successfully.${RESET}"
  pause_and_return
}

# ========= Install Rust =========
function install_rust() {
  if command -v rustc &> /dev/null; then
    echo -e "${YELLOW}[!] Rust is already installed, skipping installation.${RESET}"
    pause_and_return
    return
  fi
  echo -e "[*] Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env" || { echo -e "${RED}[-] Unable to configure Rust environment variables!${RESET}"; pause_and_return; return; }
  rustup default stable
  echo -e "${GREEN}[+] Rust installation complete.${RESET}"
  pause_and_return
}

# ========= Setup Repository =========
function setup_repository() {
  echo -e "[*] Checking nockchain repository..."
  if [ -d "$NCK_DIR" ]; then
    echo -e "${YELLOW}[?] nockchain directory already exists. Delete and re-clone? (y/n)${RESET}"
    read -r confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
      rm -rf "$NCK_DIR" "$HOME/.nockapp"
      git clone https://github.com/zorp-corp/nockchain "$NCK_DIR"
    else
      cd "$NCK_DIR" && git pull
    fi
  else
    git clone https://github.com/zorp-corp/nockchain "$NCK_DIR"
  fi
  if [ $? -ne 0 ]; then
    echo -e "${RED}[-] Failed to clone repository. Please check network or permissions!${RESET}"
    pause_and_return
    return
  fi
  cd "$NCK_DIR" || { echo -e "${RED}[-] Unable to enter nockchain directory!${RESET}"; pause_and_return; return; }
  if [ -f ".env" ]; then
    cp .env .env.bak
    echo -e "[*] .env backed up as .env.bak"
  fi
  if [ -f ".env_example" ]; then
    cp .env_example .env
    echo -e "${GREEN}[+] Environment file .env created.${RESET}"
  else
    echo -e "${RED}[-] .env_example file not found, please check the repository!${RESET}"
  fi
  echo -e "${GREEN}[+] Repository setup complete.${RESET}"
  pause_and_return
}

# ========= Build Project and Configure Environment Variables =========
function build_and_configure() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain directory does not exist. Please run option 3 to set up the repository first!${RESET}"
    pause_and_return
    return
  fi
  cd "$NCK_DIR" || { echo -e "${RED}[-] Unable to enter nockchain directory!${RESET}"; pause_and_return; return; }

  echo -e "[*] Building Nockchain components..."

  # Install hoonc first
  echo -e "[*] Installing hoonc (Hoon compiler)..."
  make install-hoonc || { echo -e "${RED}[-] make install-hoonc failed. Please check Makefile or dependencies!${RESET}"; pause_and_return; return; }

  # Update PATH for hoonc
  RC_FILE="$HOME/.bashrc"
  [[ "$SHELL" == *"zsh"* ]] && RC_FILE="$HOME/.zshrc"

  if ! grep -q "\$HOME/.cargo/bin" "$RC_FILE"; then
    echo "export PATH=\"\$HOME/.cargo/bin:\$PATH\"" >> "$RC_FILE"
    echo -e "[*] Added \$HOME/.cargo/bin to PATH in $RC_FILE"
  fi

  export PATH="$HOME/.cargo/bin:$PATH"

  if command -v hoonc &> /dev/null; then
    echo -e "${GREEN}[+] hoonc installed successfully${RESET}"
  else
    echo -e "${YELLOW}[!] Warning: hoonc command not available in PATH${RESET}"
  fi

  # Build the project
  echo -e "[*] Building Nockchain and wallet binaries..."
  make build || { echo -e "${RED}[-] make build failed. Please check Makefile or dependencies!${RESET}"; pause_and_return; return; }

  # Install wallet
  echo -e "[*] Installing nockchain-wallet..."
  make install-nockchain-wallet || { echo -e "${RED}[-] make install-nockchain-wallet failed. Please check Makefile or dependencies!${RESET}"; pause_and_return; return; }

  # Install nockchain
  echo -e "[*] Installing nockchain..."
  make install-nockchain || { echo -e "${RED}[-] make install-nockchain failed. Please check Makefile or dependencies!${RESET}"; pause_and_return; return; }

  # Update PATH again for the installed binaries
  export PATH="$HOME/.cargo/bin:$PATH"

  echo -e "[*] Configuring environment variables..."
  if ! grep -q "$NCK_DIR/target/release" "$RC_FILE"; then
    echo "export PATH=\"\$PATH:$NCK_DIR/target/release\"" >> "$RC_FILE"
  fi

  source "$RC_FILE" 2>/dev/null || echo -e "${YELLOW}[!] Please manually source $RC_FILE or reopen the terminal.${RESET}"

  # Verify installations
  echo -e "[*] Verifying installations..."
  if command -v nockchain-wallet &> /dev/null; then
    echo -e "${GREEN}[+] nockchain-wallet installed successfully${RESET}"
  else
    echo -e "${RED}[-] nockchain-wallet not found in PATH${RESET}"
  fi

  if command -v nockchain &> /dev/null; then
    echo -e "${GREEN}[+] nockchain installed successfully${RESET}"
  else
    echo -e "${RED}[-] nockchain not found in PATH${RESET}"
  fi

  echo -e "${GREEN}[+] Build and configuration complete.${RESET}"
  pause_and_return
}

# ========= Generate Wallet =========
function generate_wallet() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain directory not found. Please run options 3 and 4 first!${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || { echo -e "${RED}[-] Unable to enter nockchain directory!${RESET}"; pause_and_return; return; }

  if ! command -v nockchain-wallet &> /dev/null; then
    echo -e "${RED}[-] nockchain-wallet command not available. Please run option 4 to build and install!${RESET}"
    pause_and_return
    return
  fi

  echo -e "[*] Generating wallet key pair..."
  read -p "[?] Create new wallet? [Y/n]: " create_wallet
  create_wallet=${create_wallet:-y}

  if [[ ! "$create_wallet" =~ ^[Yy]$ ]]; then
    echo -e "[*] Wallet creation skipped."
    pause_and_return
    return
  fi

  # Generate wallet keys
  echo -e "[*] Running nockchain-wallet keygen..."
  nockchain-wallet keygen > wallet_keys_raw.txt 2>&1 || { echo -e "${RED}[-] nockchain-wallet keygen failed!${RESET}"; pause_and_return; return; }

  # Convert to text and clean up the output
  cat wallet_keys_raw.txt | strings > wallet_keys.txt 2>/dev/null || cp wallet_keys_raw.txt wallet_keys.txt

  echo -e "${GREEN}[+] Wallet keys generated and saved to $NCK_DIR/wallet_keys.txt${RESET}"

  # Debug: Show first few lines of the file to understand the format
  echo -e "[*] Wallet file contents (first 10 lines):"
  head -10 wallet_keys.txt 2>/dev/null || echo "Unable to read wallet file"
  echo ""

  # Extract public key using multiple methods
  PUBLIC_KEY=""

  # Method 1: Look for "New Public Key" followed by quoted value on next line
  if [ -z "$PUBLIC_KEY" ]; then
    PUBLIC_KEY=$(grep -a -A 1 "New Public Key" wallet_keys.txt 2>/dev/null | tail -1 | sed 's/^[[:space:]]*//' | sed 's/^"\(.*\)"$/\1/')
  fi

  # Method 2: Try grep with force text mode for "public key"
  if [ -z "$PUBLIC_KEY" ]; then
    PUBLIC_KEY=$(grep -a -i "public key" wallet_keys.txt 2>/dev/null | awk '{print $NF}' | tail -1 | sed 's/^"\(.*\)"$/\1/')
  fi

  # Method 3: Try looking for "Public Key:" pattern
  if [ -z "$PUBLIC_KEY" ]; then
    PUBLIC_KEY=$(grep -a -i "Public Key:" wallet_keys.txt 2>/dev/null | sed 's/.*Public Key: *//' | awk '{print $1}' | tail -1 | sed 's/^"\(.*\)"$/\1/')
  fi

  # Method 4: Look for quoted strings after "public" (case insensitive)
  if [ -z "$PUBLIC_KEY" ]; then
    PUBLIC_KEY=$(grep -a -i -A 1 "public" wallet_keys.txt 2>/dev/null | grep '"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
  fi

  # Method 5: Try looking for long alphanumeric strings that look like keys
  if [ -z "$PUBLIC_KEY" ]; then
    PUBLIC_KEY=$(grep -a -o '[0-9a-zA-Z]\{20,\}' wallet_keys.txt 2>/dev/null | head -1)
  fi

  # Method 6: Manual search for patterns
  if [ -z "$PUBLIC_KEY" ]; then
    echo -e "${YELLOW}[!] Automatic key extraction failed. Please manually check wallet_keys.txt${RESET}"
    echo -e "[*] Looking for key patterns in the file..."

    # Show lines that might contain the public key
    echo -e "\n${CYAN}Lines that might contain the public key:${RESET}"
    grep -a -n -i -E "(public|key|0x[0-9a-fA-F]+|[0-9a-zA-Z]{40,})" wallet_keys.txt 2>/dev/null | head -5
    echo ""

    read -p "[?] Please manually enter your public key from the output above: " manual_key
    if [ -n "$manual_key" ]; then
      PUBLIC_KEY="$manual_key"
    fi
  fi

  if [ -n "$PUBLIC_KEY" ]; then
    echo -e "${YELLOW}Extracted Public Key:${RESET}"
    echo -e "${CYAN}$PUBLIC_KEY${RESET}"
    echo ""
    echo -e "${YELLOW}[!] IMPORTANT: Save your wallet_keys.txt file securely!${RESET}"
    echo -e "${YELLOW}[!] It contains your private key and seed phrase.${RESET}"
    echo ""

    # Ask if user wants to set this as mining key
    read -p "[?] Set this public key as your mining key in .env? [Y/n]: " set_mining_key
    set_mining_key=${set_mining_key:-y}

    if [[ "$set_mining_key" =~ ^[Yy]$ ]]; then
      configure_mining_key_with_pubkey "$PUBLIC_KEY"
    else
      echo -e "${YELLOW}[!] You can set the mining key later using option 6${RESET}"
      echo -e "MINING_PUBKEY=$PUBLIC_KEY"
    fi
  else
    echo -e "${RED}[-] Unable to extract public key automatically.${RESET}"
    echo -e "${YELLOW}[!] Please check wallet_keys.txt manually for your public key.${RESET}"
    echo -e "${YELLOW}[!] You can set the mining key later using option 6.${RESET}"

    # Show file info for debugging
    echo -e "\n${CYAN}File information:${RESET}"
    ls -la wallet_keys.txt 2>/dev/null || echo "File not found"
    echo -e "\n${CYAN}File type:${RESET}"
    file wallet_keys.txt 2>/dev/null || echo "Cannot determine file type"
  fi

  # Clean up temporary file
  rm -f wallet_keys_raw.txt 2>/dev/null

  echo -e "${GREEN}[+] Wallet generation complete.${RESET}"
  echo -e "${YELLOW}[!] Remember to backup your keys using option 8!${RESET}"
  pause_and_return
}

# ========= Configure Mining Public Key =========
function configure_mining_key() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain directory not found. Please run option 3 first!${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || { echo -e "${RED}[-] Unable to enter nockchain directory!${RESET}"; pause_and_return; return; }

  if [ ! -f ".env" ]; then
    echo -e "${RED}[-] .env file not found. Please run option 3 to setup repository first!${RESET}"
    pause_and_return
    return
  fi

  echo -e "[*] Current .env file contents:"
  cat .env | grep -E "^[^#]" | head -10
  echo ""

  read -p "[?] Enter your MINING_PUBKEY: " mining_pubkey

  if [ -z "$mining_pubkey" ]; then
    echo -e "${RED}[-] No public key provided!${RESET}"
    pause_and_return
    return
  fi

  configure_mining_key_with_pubkey "$mining_pubkey"
}

# ========= Helper function to configure mining key =========
function configure_mining_key_with_pubkey() {
  local pubkey="$1"

  # Update or add MINING_PUBKEY in .env
  if grep -q "^MINING_PUBKEY=" .env; then
    sed -i "s/^MINING_PUBKEY=.*/MINING_PUBKEY=$pubkey/" .env
    echo -e "${GREEN}[+] Updated MINING_PUBKEY in .env${RESET}"
  else
    echo "MINING_PUBKEY=$pubkey" >> .env
    echo -e "${GREEN}[+] Added MINING_PUBKEY to .env${RESET}"
  fi

  echo -e "MINING_PUBKEY set to: ${CYAN}$pubkey${RESET}"
}

# ========= Backup Keys =========
function backup_keys() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain directory not found. Please run option 3 first!${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || { echo -e "${RED}[-] Unable to enter nockchain directory!${RESET}"; pause_and_return; return; }

  if ! command -v nockchain-wallet &> /dev/null; then
    echo -e "${RED}[-] nockchain-wallet command not available. Please run option 4 first!${RESET}"
    pause_and_return
    return
  fi

  echo -e "[*] Backing up wallet keys..."

  # Create backup directory
  BACKUP_DIR="$NCK_DIR/backups/$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$BACKUP_DIR"

  # Export keys using nockchain-wallet
  echo -e "[*] Exporting keys using nockchain-wallet..."
  if nockchain-wallet export-keys &> /dev/null; then
    if [ -f "keys.export" ]; then
      cp keys.export "$BACKUP_DIR/"
      echo -e "${GREEN}[+] Keys exported to $BACKUP_DIR/keys.export${RESET}"
    fi
  else
    echo -e "${YELLOW}[!] nockchain-wallet export-keys failed or no keys to export${RESET}"
  fi

  # Copy wallet_keys.txt if it exists
  if [ -f "wallet_keys.txt" ]; then
    cp wallet_keys.txt "$BACKUP_DIR/"
    echo -e "${GREEN}[+] wallet_keys.txt copied to $BACKUP_DIR/${RESET}"
  fi

  # Copy .env file
  if [ -f ".env" ]; then
    cp .env "$BACKUP_DIR/"
    echo -e "${GREEN}[+] .env file copied to $BACKUP_DIR/${RESET}"
  fi

  echo -e "${GREEN}[+] Backup completed in: $BACKUP_DIR${RESET}"
  echo -e "${YELLOW}[!] Keep your backup files secure and private!${RESET}"
  pause_and_return
}

# ========= Multi-Instance Management Functions =========

# ========= Get available port starting from base =========
function get_available_port() {
  local base_port=$1
  local port=$base_port

  while netstat -tuln 2>/dev/null | grep -q ":$port " || lsof -i :$port >/dev/null 2>&1; do
    ((port++))
  done

  echo $port
}

# ========= Setup Multi-Instance Directories =========
function setup_multi_instances() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain directory not found. Please run option 3 first!${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || { echo -e "${RED}[-] Unable to enter nockchain directory!${RESET}"; pause_and_return; return; }

  echo -e "[*] Setting up multi-instance directories..."
  echo -e "[*] Maximum instances based on CPU cores: $MAX_INSTANCES"

  read -p "[?] How many instances do you want to setup? (1-$MAX_INSTANCES): " num_instances

  if ! [[ "$num_instances" =~ ^[0-9]+$ ]] || [ "$num_instances" -lt 1 ] || [ "$num_instances" -gt "$MAX_INSTANCES" ]; then
    echo -e "${RED}[-] Invalid number. Please enter a number between 1 and $MAX_INSTANCES${RESET}"
    pause_and_return
    return
  fi

  # Check if .env exists and has MINING_PUBKEY
  if [ ! -f ".env" ] || ! grep -q "^MINING_PUBKEY=" .env; then
    echo -e "${RED}[-] No MINING_PUBKEY found in .env. Please run option 5 or 6 first!${RESET}"
    pause_and_return
    return
  fi

  MINING_PUBKEY=$(grep "^MINING_PUBKEY=" .env | cut -d'=' -f2)

  if [ -z "$MINING_PUBKEY" ]; then
    echo -e "${RED}[-] MINING_PUBKEY is empty. Please run option 5 or 6 first!${RESET}"
    pause_and_return
    return
  fi

  echo -e "[*] Using MINING_PUBKEY: ${CYAN}$MINING_PUBKEY${RESET}"

  # Create instance directories
  for ((i=1; i<=num_instances; i++)); do
    instance_dir="node$i"
    echo -e "[*] Setting up instance $i in directory: $instance_dir"

    mkdir -p "$instance_dir"

    # Copy .env to instance directory
    cp .env "$instance_dir/"

    # Create instance-specific env file with unique ports
    base_peer_port=$((33416 + (i-1)*10))
    peer_port=$(get_available_port $base_peer_port)

    echo "# Instance $i specific configuration" >> "$instance_dir/.env"
    echo "PEER_PORT=$peer_port" >> "$instance_dir/.env"
    echo "INSTANCE_ID=$i" >> "$instance_dir/.env"

    echo -e "${GREEN}[+] Instance $i setup complete - Port: $peer_port${RESET}"
  done

  echo -e "${GREEN}[+] Multi-instance setup complete!${RESET}"
  echo -e "${YELLOW}[!] Use option 7 to start mining instances${RESET}"
  pause_and_return
}

# ========= Start Single Instance =========
function start_single_instance() {
  local instance_num=$1
  local instance_dir="node$instance_num"
  local original_dir=$(pwd)

  # Silently skip if directory doesn't exist
  if [ ! -d "$instance_dir" ]; then
    return 1
  fi

  # Get absolute path of instance directory
  local instance_path="$NCK_DIR/$instance_dir"

  cd "$instance_dir" || { echo -e "${RED}[-] Unable to enter $instance_dir!${RESET}"; return 1; }

  if [ ! -f ".env" ]; then
    echo -e "${RED}[-] .env file not found in $instance_dir${RESET}"
    cd "$original_dir"
    return 1
  fi

  # Source the instance env
  source .env

  if [ -z "$MINING_PUBKEY" ]; then
    echo -e "${RED}[-] MINING_PUBKEY not found in $instance_dir/.env${RESET}"
    cd "$original_dir"
    return 1
  fi

  # Clean data directory if requested
  if [ -d ".data.nockchain" ]; then
    echo -e "${YELLOW}[?] Instance $instance_num: Clean data directory? (y/n)${RESET}"
    read -r confirm_clean
    if [[ "$confirm_clean" == "y" || "$confirm_clean" == "Y" ]]; then
      mv .data.nockchain .data.nockchain.bak-$(date +%F-%H%M%S) 2>/dev/null
      echo -e "${GREEN}[+] Instance $instance_num: Data directory cleaned${RESET}"
    fi
  fi

  # Clean existing screen session
  screen -ls | grep -q "miner$instance_num" && screen -X -S "miner$instance_num" quit

  # Build nockchain command with proper working directory
  NOCKCHAIN_CMD="cd \"$instance_path\" && RUST_LOG=info"

  if [ -n "$PEER_PORT" ]; then
    NOCKCHAIN_CMD="$NOCKCHAIN_CMD \"$NCK_DIR/target/release/nockchain\" --bind /ip4/0.0.0.0/udp/$PEER_PORT/quic-v1 --mining-pubkey \"$MINING_PUBKEY\" --mine"
  else
    NOCKCHAIN_CMD="$NOCKCHAIN_CMD \"$NCK_DIR/target/release/nockchain\" --mining-pubkey \"$MINING_PUBKEY\" --mine"
  fi

  echo -e "[*] Starting instance $instance_num..."
  echo -e "[*] Working directory: $instance_path"
  echo -e "[*] Command: $NOCKCHAIN_CMD"

  # Return to original directory before starting screen
  cd "$original_dir"

  # Start in screen session with proper working directory
  screen -dmS "miner$instance_num" bash -c "$NOCKCHAIN_CMD 2>&1 | tee \"$instance_path/miner$instance_num.log\"; echo 'Instance $instance_num exited, check log'; sleep 30"

  sleep 2

  if screen -ls | grep -q "miner$instance_num"; then
    echo -e "${GREEN}[+] Instance $instance_num started successfully${RESET}"
    if [ -n "$PEER_PORT" ]; then
      echo -e "    Port: $PEER_PORT"
    fi
    echo -e "    Working directory: $instance_path"
    echo -e "    Screen session: miner$instance_num"
    echo -e "    Log file: $instance_path/miner$instance_num.log"
    return 0
  else
    echo -e "${RED}[-] Failed to start instance $instance_num${RESET}"
    echo -e "${YELLOW}[!] Check log: $instance_path/miner$instance_num.log${RESET}"
    return 1
  fi
}

# ========= Start Miner Instances =========
function start_miner_instances() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain directory not found. Please run option 3 first!${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || { echo -e "${RED}[-] Unable to enter nockchain directory!${RESET}"; pause_and_return; return; }

  # Check if nockchain command is available
  if ! command -v nockchain &> /dev/null && [ ! -f "$NCK_DIR/target/release/nockchain" ]; then
    echo -e "${RED}[-] nockchain command not available. Please run option 4 first!${RESET}"
    pause_and_return
    return
  fi

  # Check if we have instance directories
  instance_dirs=()
  for d in node*; do
    [ -d "$d" ] && instance_dirs+=("$d")
  done

  if [ ${#instance_dirs[@]} -eq 0 ]; then
    echo -e "${YELLOW}[!] No instance directories found. Setting up single instance...${RESET}"

    # Check if we have .env and MINING_PUBKEY
    if [ ! -f ".env" ] || ! grep -q "^MINING_PUBKEY=" .env; then
      echo -e "${RED}[-] No MINING_PUBKEY found. Please run option 5 or 6 first!${RESET}"
      pause_and_return
      return
    fi

    # Start single instance in main directory
    MINING_PUBKEY=$(grep "^MINING_PUBKEY=" .env | cut -d'=' -f2)

    if [ -z "$MINING_PUBKEY" ]; then
      echo -e "${RED}[-] MINING_PUBKEY is empty!${RESET}"
      pause_and_return
      return
    fi

    echo -e "[*] Starting single miner instance..."

    # Clean data directory if requested
    if [ -d ".data.nockchain" ]; then
      echo -e "${YELLOW}[?] Clean data directory? (y/n)${RESET}"
      read -r confirm_clean
      if [[ "$confirm_clean" == "y" || "$confirm_clean" == "Y" ]]; then
        mv .data.nockchain .data.nockchain.bak-$(date +%F-%H%M%S) 2>/dev/null
        echo -e "${GREEN}[+] Data directory cleaned${RESET}"
      fi
    fi

    # Clean existing screen session
    screen -ls | grep -q "miner" && screen -X -S miner quit

    # Start single instance
    NOCKCHAIN_CMD="RUST_LOG=info $NCK_DIR/target/release/nockchain --mining-pubkey \"$MINING_PUBKEY\" --mine"

    screen -dmS miner bash -c "$NOCKCHAIN_CMD 2>&1 | tee miner.log; echo 'Miner exited, check log'; sleep 30"

    sleep 2

    if screen -ls | grep -q "miner"; then
      echo -e "${GREEN}[+] Single miner instance started successfully${RESET}"
      echo -e "    Screen session: miner"
      echo -e "    Log file: $NCK_DIR/miner.log"
    else
      echo -e "${RED}[-] Failed to start miner instance${RESET}"
    fi

  else
    echo -e "[*] Found ${#instance_dirs[@]} instance directories: ${instance_dirs[*]}"
    echo -e "[*] Multi-instance startup options:"
    echo -e "  1) Start all existing instances"
    echo -e "  2) Start specific instance"
    echo -e "  3) Start range of instances"
    echo -e "  0) Return to menu"

    read -p "Select option: " startup_choice

    case "$startup_choice" in
      1)
        echo -e "[*] Starting all existing instances..."
        started=0
        for instance_dir in "${instance_dirs[@]}"; do
          instance_num=${instance_dir#node}
          echo -e "[*] Processing $instance_dir (instance $instance_num)..."
          if start_single_instance "$instance_num"; then
            ((started++))
          fi
        done
        echo -e "${GREEN}[+] Started $started out of ${#instance_dirs[@]} instances successfully${RESET}"
        ;;
      2)
        echo -e "Available instances: ${instance_dirs[*]}"
        read -p "Enter instance number to start: " instance_num
        if [ -d "node$instance_num" ]; then
          start_single_instance "$instance_num"
        else
          echo -e "${RED}[-] Instance node$instance_num not found${RESET}"
        fi
        ;;
      3)
        echo -e "Available instances: ${instance_dirs[*]}"
        read -p "Enter start instance number: " start_num
        read -p "Enter end instance number: " end_num

        if [[ "$start_num" =~ ^[0-9]+$ ]] && [[ "$end_num" =~ ^[0-9]+$ ]] && [ "$start_num" -le "$end_num" ]; then
          started=0
          echo -e "[*] Starting instances $start_num to $end_num..."
          for ((i=start_num; i<=end_num; i++)); do
            if [ -d "node$i" ]; then
              echo -e "[*] Processing node$i..."
              if start_single_instance "$i"; then
                ((started++))
              fi
            else
              echo -e "${YELLOW}[!] Skipping node$i (directory not found)${RESET}"
            fi
          done
          echo -e "${GREEN}[+] Started $started instances in range $start_num-$end_num${RESET}"
        else
          echo -e "${RED}[-] Invalid range${RESET}"
        fi
        ;;
      0)
        pause_and_return
        return
        ;;
      *)
        echo -e "${RED}[-] Invalid option${RESET}"
        ;;
    esac
  fi

  # Show final status
  echo -e "\n${CYAN}=== Instance Status ===${RESET}"
  active_sessions=($(screen -ls | grep -o 'miner[0-9]*' | sort))

  if [ ${#active_sessions[@]} -gt 0 ]; then
    echo -e "${GREEN}Active mining sessions:${RESET}"
    for session in "${active_sessions[@]}"; do
      echo -e "  - $session (use 'screen -r $session' to view)"
    done

    echo -e "\n${YELLOW}Useful commands:${RESET}"
    echo -e "  View logs: screen -r <session_name>"
    echo -e "  Detach from screen: Ctrl+A then D"
    echo -e "  Stop instance: screen -X -S <session_name> quit"
    echo -e "  List sessions: screen -ls"
  else
    echo -e "${RED}No active mining sessions found${RESET}"
  fi

  pause_and_return
}

# ========= Stop Mining Instances =========
function stop_miner_instances() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain directory not found.${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || { echo -e "${RED}[-] Unable to enter nockchain directory!${RESET}"; pause_and_return; return; }

  # Find all active miner sessions
  active_sessions=($(screen -ls | grep -o 'miner[0-9]*' | sort))

  if [ ${#active_sessions[@]} -eq 0 ]; then
    echo -e "${YELLOW}[!] No active mining sessions found${RESET}"
    pause_and_return
    return
  fi

  echo -e "[*] Active mining sessions: ${active_sessions[*]}"
  echo -e "[*] Stop options:"
  echo -e "  1) Stop all instances"
  echo -e "  2) Stop specific instance"
  echo -e "  3) Stop range of instances"
  echo -e "  0) Return to menu"

  read -p "Select option: " stop_choice

  case "$stop_choice" in
    1)
      echo -e "[*] Stopping all mining instances..."
      for session in "${active_sessions[@]}"; do
        screen -X -S "$session" quit
        echo -e "  ${GREEN}[+] Stopped $session${RESET}"
      done
      echo -e "${GREEN}[+] All mining instances stopped${RESET}"
      ;;
    2)
      echo -e "Active sessions: ${active_sessions[*]}"
      read -p "Enter session name to stop (e.g., miner1): " session_name
      if screen -ls | grep -q "$session_name"; then
        screen -X -S "$session_name" quit
        echo -e "${GREEN}[+] Stopped $session_name${RESET}"
      else
        echo -e "${RED}[-] Session $session_name not found${RESET}"
      fi
      ;;
    3)
      read -p "Enter start instance number: " start_num
      read -p "Enter end instance number: " end_num

      if [[ "$start_num" =~ ^[0-9]+$ ]] && [[ "$end_num" =~ ^[0-9]+$ ]] && [ "$start_num" -le "$end_num" ]; then
        stopped=0
        for ((i=start_num; i<=end_num; i++)); do
          session_name="miner$i"
          if screen -ls | grep -q "$session_name"; then
            screen -X -S "$session_name" quit
            echo -e "  ${GREEN}[+] Stopped $session_name${RESET}"
            ((stopped++))
          fi
        done
        echo -e "${GREEN}[+] Stopped $stopped instances${RESET}"
      else
        echo -e "${RED}[-] Invalid range${RESET}"
      fi
      ;;
    0)
      pause_and_return
      return
      ;;
    *)
      echo -e "${RED}[-] Invalid option${RESET}"
      ;;
  esac

  pause_and_return
}

# ========= Check Instance Status =========
function check_instance_status() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain directory not found.${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || { echo -e "${RED}[-] Unable to enter nockchain directory!${RESET}"; pause_and_return; return; }

  echo -e "${CYAN}=== Instance Status Report ===${RESET}"

  # Check for instance directories
  instance_dirs=($(ls -d node* 2>/dev/null | sort -V))

  if [ ${#instance_dirs[@]} -eq 0 ]; then
    echo -e "${YELLOW}[!] No multi-instance directories found${RESET}"

    # Check for single instance
    if screen -ls | grep -q "miner" && [ ! "$(screen -ls | grep -o 'miner[0-9]')" ]; then
      echo -e "${GREEN}[+] Single miner instance is running${RESET}"
      echo -e "  Session: miner"
      echo -e "  Log: $NCK_DIR/miner.log"
    else
      echo -e "${RED}[-] No mining instances running${RESET}"
    fi
  else
    echo -e "[*] Found ${#instance_dirs[@]} instance directories"

    for instance_dir in "${instance_dirs[@]}"; do
      instance_num=${instance_dir#node}
      session_name="miner$instance_num"

      echo -e "\n${BOLD}Instance $instance_num ($instance_dir):${RESET}"

      if screen -ls | grep -q "$session_name"; then
        echo -e "  Status: ${GREEN}Running${RESET}"
        echo -e "  Session: $session_name"

        # Get port info if available
        if [ -f "$instance_dir/.env" ]; then
          peer_port=$(grep "^PEER_PORT=" "$instance_dir/.env" 2>/dev/null | cut -d'=' -f2)
          if [ -n "$peer_port" ]; then
            echo -e "  Port: $peer_port"
          fi
        fi

        # Check log file
        log_file="$instance_dir/miner$instance_num.log"
        if [ -f "$log_file" ]; then
          echo -e "  Log: $log_file"
          log_size=$(du -h "$log_file" 2>/dev/null | cut -f1)
          echo -e "  Log size: $log_size"
        fi
      else
        echo -e "  Status: ${RED}Stopped${RESET}"
      fi
    done
  fi

  # Show overall active sessions
  active_sessions=($(screen -ls | grep -o 'miner[0-9]*' | sort))
  echo -e "\n${CYAN}Active Sessions:${RESET}"
  if [ ${#active_sessions[@]} -gt 0 ]; then
    for session in "${active_sessions[@]}"; do
      echo -e "  - $session"
    done
  else
    echo -e "  None"
  fi

  # Show system resources
  echo -e "\n${CYAN}System Resources:${RESET}"
  echo -e "  CPU Cores: $MAX_INSTANCES"
  echo -e "  Load Average: $(uptime | awk -F'load average:' '{print $2}')"
  echo -e "  Memory Usage: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"

  pause_and_return
}

# ========= Clean Instance Data =========
function clean_instance_data() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain directory not found.${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || { echo -e "${RED}[-] Unable to enter nockchain directory!${RESET}"; pause_and_return; return; }

  echo -e "${YELLOW}[!] This will clean blockchain data from instances${RESET}"
  echo -e "${YELLOW}[!] Instances will need to resync from the network${RESET}"

  instance_dirs=()
  for d in node*; do
    [ -d "$d" ] && instance_dirs+=("$d")
  done

  if [ ${#instance_dirs[@]} -eq 0 ]; then
    echo -e "[*] Cleaning main directory data..."
    if [ -d ".data.nockchain" ]; then
      read -p "[?] Clean main directory .data.nockchain? (y/n): " confirm
      if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        mv .data.nockchain .data.nockchain.bak-$(date +%F-%H%M%S) 2>/dev/null
        echo -e "${GREEN}[+] Main directory data cleaned${RESET}"
      fi
    else
      echo -e "${YELLOW}[!] No .data.nockchain found in main directory${RESET}"
    fi
  else
    echo -e "[*] Clean options:"
    echo -e "  1) Clean all instance data"
    echo -e "  2) Clean specific instance"
    echo -e "  3) Clean range of instances"
    echo -e "  0) Return to menu"

    read -p "Select option: " clean_choice

    case "$clean_choice" in
      1)
        read -p "[?] Clean data for all instances? (y/n): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
          for instance_dir in "${instance_dirs[@]}"; do
            instance_num=${instance_dir#node}
            if [ -d "$instance_dir/.data.nockchain" ]; then
              mv "$instance_dir/.data.nockchain" "$instance_dir/.data.nockchain.bak-$(date +%F-%H%M%S)" 2>/dev/null
              echo -e "  ${GREEN}[+] Cleaned data for instance $instance_num${RESET}"
            fi
          done
          echo -e "${GREEN}[+] All instance data cleaned${RESET}"
        fi
        ;;
      2)
        echo -e "Available instances: ${instance_dirs[*]}"
        read -p "Enter instance number to clean: " instance_num
        instance_dir="node$instance_num"

        if [ -d "$instance_dir" ]; then
          if [ -d "$instance_dir/.data.nockchain" ]; then
            read -p "[?] Clean data for instance $instance_num? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
              mv "$instance_dir/.data.nockchain" "$instance_dir/.data.nockchain.bak-$(date +%F-%H%M%S)" 2>/dev/null
              echo -e "${GREEN}[+] Cleaned data for instance $instance_num${RESET}"
            fi
          else
            echo -e "${YELLOW}[!] No data directory found for instance $instance_num${RESET}"
          fi
        else
          echo -e "${RED}[-] Instance $instance_num not found${RESET}"
        fi
        ;;
      3)
        read -p "Enter start instance number: " start_num
        read -p "Enter end instance number: " end_num

        if [[ "$start_num" =~ ^[0-9]+$ ]] && [[ "$end_num" =~ ^[0-9]+$ ]] && [ "$start_num" -le "$end_num" ]; then
          read -p "[?] Clean data for instances $start_num to $end_num? (y/n): " confirm
          if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            cleaned=0
            for ((i=start_num; i<=end_num; i++)); do
              instance_dir="node$i"
              if [ -d "$instance_dir/.data.nockchain" ]; then
                mv "$instance_dir/.data.nockchain" "$instance_dir/.data.nockchain.bak-$(date +%F-%H%M%S)" 2>/dev/null
                echo -e "  ${GREEN}[+] Cleaned data for instance $i${RESET}"
                ((cleaned++))
              fi
            done
            echo -e "${GREEN}[+] Cleaned data for $cleaned instances${RESET}"
          fi
        else
          echo -e "${RED}[-] Invalid range${RESET}"
        fi
        ;;
      0)
        pause_and_return
        return
        ;;
      *)
        echo -e "${RED}[-] Invalid option${RESET}"
        ;;
    esac
  fi

  pause_and_return
}

# ========= View Node Logs =========
function view_logs() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain directory not found.${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || { echo -e "${RED}[-] Unable to enter nockchain directory!${RESET}"; pause_and_return; return; }

  # Find all active sessions
  active_sessions=($(screen -ls | grep -o 'miner[0-9]*' | sort))

  if [ ${#active_sessions[@]} -eq 0 ]; then
    echo -e "${RED}[-] No active mining sessions found!${RESET}"
    pause_and_return
    return
  fi

  echo -e "${BOLD}${BLUE}View node logs:${RESET}"

  # Show single miner option if exists
  if screen -ls | grep -q "miner" && [ ! "$(screen -ls | grep -o 'miner[0-9]')" ]; then
    echo -e "  1) Single miner instance"
  fi

  # Show numbered instances
  local option_num=2
  local instance_options=()

  for session in "${active_sessions[@]}"; do
    if [[ "$session" =~ ^miner[0-9]+$ ]]; then
      instance_num=${session#miner}
      echo -e "  $option_num) Instance $instance_num ($session)"
      instance_options[$option_num]="$session"
      ((option_num++))
    fi
  done

  echo -e "  98) View log file (without screen)"
  echo -e "  99) Tail all logs"
  echo -e "  0) Return to main menu"

  read -p "Select which log to view: " log_choice

  case "$log_choice" in
    1)
      if screen -ls | grep -q "miner" && [ ! "$(screen -ls | grep -o 'miner[0-9]')" ]; then
        screen -r miner
      else
        echo -e "${RED}[-] Single miner instance not found!${RESET}"
      fi
      ;;
    98)
      echo -e "[*] Available log files:"
      if [ -f "miner.log" ]; then
        echo -e "  - miner.log (main)"
      fi

      for instance_dir in node*; do
        if [ -d "$instance_dir" ]; then
          instance_num=${instance_dir#node}
          log_file="$instance_dir/miner$instance_num.log"
          if [ -f "$log_file" ]; then
            echo -e "  - $log_file"
          fi
        fi
      done

      read -p "Enter log file path to view: " log_file
      if [ -f "$log_file" ]; then
        echo -e "${YELLOW}[!] Showing last 50 lines of $log_file (Press Ctrl+C to exit)${RESET}"
        tail -f -n 50 "$log_file"
      else
        echo -e "${RED}[-] Log file not found: $log_file${RESET}"
      fi
      ;;
    99)
      echo -e "${YELLOW}[!] Showing last 20 lines from all log files:${RESET}"

      if [ -f "miner.log" ]; then
        echo -e "\n${CYAN}=== Main miner.log ===${RESET}"
        tail -n 20 "miner.log" 2>/dev/null || echo "Unable to read miner.log"
      fi

      for instance_dir in node*; do
        if [ -d "$instance_dir" ]; then
          instance_num=${instance_dir#node}
          log_file="$instance_dir/miner$instance_num.log"
          if [ -f "$log_file" ]; then
            echo -e "\n${CYAN}=== Instance $instance_num ===${RESET}"
            tail -n 20 "$log_file" 2>/dev/null || echo "Unable to read $log_file"
          fi
        fi
      done

      echo -e "\n${YELLOW}Press any key to continue...${RESET}"
      read -n1 -r
      ;;
    0)
      pause_and_return
      return
      ;;
    *)
      if [ -n "${instance_options[$log_choice]}" ]; then
        session_name="${instance_options[$log_choice]}"
        screen -r "$session_name"
      else
        echo -e "${RED}[-] Invalid option!${RESET}"
      fi
      ;;
  esac
  pause_and_return
}

# ========= Wait for Any Key to Continue =========
function pause_and_return() {
  echo ""
  read -n1 -r -p "Press any key to return to main menu..." key
  main_menu
}

# ========= Main Menu =========
function main_menu() {
  show_banner
  echo "Please select an operation:"
  echo ""
  echo "${CYAN}=== Setup & Installation ===${RESET}"
  echo "  1) Install system dependencies"
  echo "  2) Install Rust"
  echo "  3) Setup repository"
  echo "  4) Build project and configure environment variables"
  echo ""
  echo "${CYAN}=== Wallet Management ===${RESET}"
  echo "  5) Generate wallet"
  echo "  6) Set mining public key"
  echo "  8) Backup keys"
  echo ""
  echo "${CYAN}=== Multi-Instance Setup ===${RESET}"
  echo "  10) Setup multi-instance directories"
  echo ""
  echo "${CYAN}=== Mining Operations ===${RESET}"
  echo "  7) Start mining instances"
  echo "  11) Stop mining instances"
  echo "  12) Check instance status"
  echo "  13) Clean instance data"
  echo ""
  echo "${CYAN}=== Monitoring ===${RESET}"
  echo "  9) View node logs"
  echo ""
  echo "${CYAN}=== Advanced ===${RESET}"
  echo "  20) Check wallet balance"
  echo "  21) Network diagnostics"
  echo ""
  echo "  0) Exit"
  echo ""
  read -p "Enter number: " choice
  case "$choice" in
    1) install_dependencies ;;
    2) install_rust ;;
    3) setup_repository ;;
    4) build_and_configure ;;
    5) generate_wallet ;;
    6) configure_mining_key ;;
    7) start_miner_instances ;;
    8) backup_keys ;;
    9) view_logs ;;
    10) setup_multi_instances ;;
    11) stop_miner_instances ;;
    12) check_instance_status ;;
    13) clean_instance_data ;;
    21) network_diagnostics ;;
    0) echo -e "${GREEN}Exited.${RESET}"; exit 0 ;;
    *) echo -e "${RED}[-] Invalid option!${RESET}"; pause_and_return ;;
  esac
}

# ========= Check Wallet Balance =========
function check_wallet_balance() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain directory not found.${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || { echo -e "${RED}[-] Unable to enter nockchain directory!${RESET}"; pause_and_return; return; }

  if ! command -v nockchain-wallet &> /dev/null; then
    echo -e "${RED}[-] nockchain-wallet command not available. Please run option 4 first!${RESET}"
    pause_and_return
    return
  fi

  echo -e "[*] Checking wallet balance and notes..."
  echo -e "[*] Working from directory: $(pwd)"

  # Look for socket files in instance directories
  socket_file=""
  found_instance=""

  for instance_dir in node*; do
    if [ -d "$instance_dir" ] && [ -f "$instance_dir/.socket/nockchain.sock" ]; then
      socket_file="$instance_dir/.socket/nockchain.sock"
      found_instance="$instance_dir"
      echo -e "[*] Found socket in $instance_dir"
      break
    fi
  done

  if [ -z "$socket_file" ]; then
    echo -e "${RED}[-] No nockchain socket found in any node directory!${RESET}"
    echo -e "${YELLOW}[!] Make sure at least one mining instance is running.${RESET}"
    echo -e "${YELLOW}[!] Socket should be located at: node*/.socket/nockchain.sock${RESET}"

    # Debug: Show what directories exist
    echo -e "\n${CYAN}=== Debug: Available directories ===${RESET}"
    ls -la | grep "^d" | grep node || echo "No node directories found"

    # Check if any instances are running
    active_sessions=($(screen -ls 2>/dev/null | grep -o 'miner[0-9]*' | sort))
    if [ ${#active_sessions[@]} -gt 0 ]; then
      echo -e "\n${YELLOW}Active sessions found: ${active_sessions[*]}${RESET}"
      echo -e "${YELLOW}But no socket files detected. Instance may still be starting up.${RESET}"
    else
      echo -e "\n${RED}No active mining sessions found.${RESET}"
      echo -e "${YELLOW}Please start mining instances using option 7 first.${RESET}"
    fi

    pause_and_return
    return
  fi

  echo -e "\n${CYAN}=== Wallet Balance Check ===${RESET}"
  echo -e "[*] Using socket: ${CYAN}$socket_file${RESET}"
  echo -e "[*] From instance: ${CYAN}$found_instance${RESET}"

  # Get mining pubkey from .env
  if [ -f ".env" ] && grep -q "^MINING_PUBKEY=" .env; then
    MINING_PUBKEY=$(grep "^MINING_PUBKEY=" .env | cut -d'=' -f2)

    echo -e "[*] Checking notes for pubkey: ${CYAN}$MINING_PUBKEY${RESET}"

    # List notes by pubkey
    echo -e "\n${YELLOW}=== Notes for your pubkey ===${RESET}"
    nockchain-wallet --nockchain-socket "$socket_file" list-notes-by-pubkey "$MINING_PUBKEY" 2>/dev/null || {
      echo -e "${RED}[-] Failed to retrieve notes. Make sure mining instance is running and synced.${RESET}"
      echo -e "${YELLOW}[!] This may be normal if the node is still syncing or no notes exist yet.${RESET}"
    }

    echo -e "\n${YELLOW}=== All notes seen by node ===${RESET}"
    nockchain-wallet --nockchain-socket "$socket_file" list-notes 2>/dev/null || {
      echo -e "${RED}[-] Failed to retrieve all notes.${RESET}"
      echo -e "${YELLOW}[!] This may be normal if the node is still syncing.${RESET}"
    }
  else
    echo -e "${RED}[-] No MINING_PUBKEY found in .env. Please run option 6 first!${RESET}"
  fi

  pause_and_return
}

# ========= Network Diagnostics =========
function network_diagnostics() {
  echo -e "${CYAN}=== Network Diagnostics ===${RESET}"

  # Check basic connectivity
  echo -e "\n${YELLOW}=== Basic Connectivity ===${RESET}"
  echo -e "[*] Testing internet connectivity..."
  if ping -c 3 8.8.8.8 &> /dev/null; then
    echo -e "${GREEN}[+] Internet connectivity: OK${RESET}"
  else
    echo -e "${RED}[-] Internet connectivity: FAILED${RESET}"
  fi

  # Check Nockchain network
  echo -e "\n[*] Testing Nockchain network connectivity..."
  if ping -c 3 nockchain-backbone.zorp.io &> /dev/null; then
    echo -e "${GREEN}[+] Nockchain backbone connectivity: OK${RESET}"
  else
    echo -e "${RED}[-] Nockchain backbone connectivity: FAILED${RESET}"
    echo -e "${YELLOW}[!] Suggestions:${RESET}"
    echo -e "    1) Check DNS: dig nockchain-backbone.zorp.io"
    echo -e "    2) Check firewall: ufw status"
    echo -e "    3) Sync time: sudo ntpdate pool.ntp.org"
    echo -e "    4) Test UDP: nc -zu nockchain-backbone.zorp.io 33416"
  fi

  # Check port availability
  echo -e "\n${YELLOW}=== Port Status ===${RESET}"
  base_ports=(33416 33417 33418 33419 33420)
  for port in "${base_ports[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$port " || lsof -i :$port >/dev/null 2>&1; then
      echo -e "Port $port: ${RED}OCCUPIED${RESET}"
    else
      echo -e "Port $port: ${GREEN}AVAILABLE${RESET}"
    fi
  done

  # Check system resources
  echo -e "\n${YELLOW}=== System Resources ===${RESET}"
  echo -e "CPU Cores: $MAX_INSTANCES"
  echo -e "Load Average:$(uptime | awk -F'load average:' '{print $2}')"
  echo -e "Memory Usage: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')"
  echo -e "Disk Usage: $(df -h . | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"

  # Check active mining sessions
  echo -e "\n${YELLOW}=== Active Mining Sessions ===${RESET}"
  if [ -d "$NCK_DIR" ]; then
    cd "$NCK_DIR"
    active_sessions=($(screen -ls 2>/dev/null | grep -o 'miner[0-9]*' | sort))
    if [ ${#active_sessions[@]} -gt 0 ]; then
      echo -e "${GREEN}Active sessions: ${active_sessions[*]}${RESET}"
    else
      echo -e "${YELLOW}No active mining sessions${RESET}"
    fi
  else
    echo -e "${RED}Nockchain directory not found${RESET}"
  fi

  # Check for common issues
  echo -e "\n${YELLOW}=== Common Issues Check ===${RESET}"

  # Check if screen is installed
  if command -v screen &> /dev/null; then
    echo -e "${GREEN}[+] screen command: Available${RESET}"
  else
    echo -e "${RED}[-] screen command: Missing (install with: sudo apt install screen)${RESET}"
  fi

  # Check if nockchain binaries exist
  if command -v nockchain &> /dev/null; then
    echo -e "${GREEN}[+] nockchain binary: Available${RESET}"
  else
    echo -e "${RED}[-] nockchain binary: Missing (run option 4 to build)${RESET}"
  fi

  if command -v nockchain-wallet &> /dev/null; then
    echo -e "${GREEN}[+] nockchain-wallet binary: Available${RESET}"
  else
    echo -e "${RED}[-] nockchain-wallet binary: Missing (run option 4 to build)${RESET}"
  fi

  pause_and_return
}

# ========= Start Main Program =========
main_menu