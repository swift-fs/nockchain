# Nockchain Multi-Instance Mining Setup Script

This script provides an interactive menu-driven interface to set up and manage Nockchain mining instances with multi-core support.

## Prerequisites

- Ubuntu 22.04 or similar Linux distribution with apt package manager
- Sudo privileges
- At least 8GB RAM (32-64GB recommended for multiple instances)
- At least 200GB free disk space
- Internet connection

## Quick Start

1. **Download and Run the Script**

   ```bash
   wget https://raw.githubusercontent.com/your-repo/nockchain/main/nock.sh
   chmod +x nock.sh
   ./nock.sh
   ```

2. **Complete Setup (Run in order)**
   - Option 1: Install system dependencies
   - Option 2: Install Rust
   - Option 3: Setup repository
   - Option 4: Build project and configure environment variables
   - Option 5: Generate wallet
   - Option 10: Setup multi-instance directories (optional)
   - Option 7: Start mining instances

## Menu Options

### Setup & Installation

- **1) Install system dependencies** - Installs required system packages including clang, llvm-dev, libclang-dev
- **2) Install Rust** - Installs Rust toolchain via rustup
- **3) Setup repository** - Clones Nockchain repository and sets up environment files
- **4) Build project and configure environment variables** - Builds all Nockchain components

### Wallet Management

- **5) Generate wallet** - Creates new wallet keys and optionally sets mining public key
- **6) Set mining public key** - Manually configure your mining public key
- **8) Backup keys** - Creates timestamped backup of wallet keys and configuration

### Multi-Instance Setup

- **10) Setup multi-instance directories** - Creates multiple mining instances (limited by CPU cores)

### Mining Operations

- **7) Start mining instances** - Starts single or multiple mining instances
- **11) Stop mining instances** - Stops running mining instances
- **12) Check instance status** - Shows status of all instances and system resources
- **13) Clean instance data** - Removes blockchain data to force resync

### Monitoring

- **9) View node logs** - Access real-time logs via screen sessions or log files

### Advanced

- **21) Network diagnostics** - Tests connectivity, ports, and system resources

## Multi-Instance Mining

The script automatically detects your CPU cores and allows you to run multiple mining instances:

- **CPU Detection**: Automatically detects available CPU cores using `nproc`
- **Port Management**: Each instance gets a unique port starting from 33416
- **Directory Structure**: Creates separate `node1`, `node2`, etc. directories
- **Independent Operation**: Each instance runs in its own screen session

### Instance Management

```bash
# View all running instances
screen -ls

# Attach to specific instance
screen -r miner1
screen -r miner2

# Detach from screen session
Ctrl+A then D

# Stop specific instance
screen -X -S miner1 quit
```

## Directory Structure

```
$HOME/nockchain/           # Main installation directory
├── .env                   # Main environment configuration
├── wallet_keys.txt        # Generated wallet keys
├── target/release/        # Built binaries
├── node1/                 # Instance 1 directory
│   ├── .env              # Instance-specific config
│   ├── .data.nockchain/  # Blockchain data
│   ├── .socket/          # Node socket
│   └── miner1.log        # Instance logs
├── node2/                 # Instance 2 directory
│   └── ...

```

## Environment Configuration

The script manages these key environment variables:

- `MINING_PUBKEY`: Your wallet's public key for mining rewards
- `PEER_PORT`: Unique port for each instance (33416, 33426, 33436, etc.)
- `INSTANCE_ID`: Numeric identifier for each instance
- `RUST_LOG`: Logging level (set to "info")

## Wallet Security

⚠️ **IMPORTANT SECURITY NOTES**:

1. **Backup your wallet**: Use option 8 to create timestamped backups
2. **Secure storage**: Keep `wallet_keys.txt` and backups in secure locations
3. **Private keys**: Never share your private keys or seed phrases
4. **Public key**: Only the public key is used for mining configuration

## Troubleshooting

### Installation Issues

- Ensure you have sudo privileges
- Check internet connectivity
- Verify sufficient disk space (200GB+)
- Make sure you're on a supported Linux distribution

### Wallet Generation Problems

- Ensure step 4 (build) completed successfully
- Check if `nockchain-wallet` binary exists
- Review wallet_keys.txt file format

### Mining Instance Issues

- Verify instances are created (option 10)
- Check system resources (option 12)
- Review instance logs (option 9)
- Ensure ports aren't blocked by firewall

### Socket Issues

- Socket files are located at `nodeX/.socket/nockchain_npc.sock`
- Make sure mining instances are fully started before checking status
- Instances may take time to create socket files during startup

### Network Connectivity

- Use option 21 for comprehensive network diagnostics
- Check DNS resolution for nockchain-backbone.zorp.io
- Verify UDP port connectivity
- Ensure system time is synchronized

## System Requirements by Instance Count

| Instances | RAM (Recommended) | CPU Cores | Notes                 |
| --------- | ----------------- | --------- | --------------------- |
| 1         | 8GB               | 2+        | Basic setup           |
| 2-4       | 16GB              | 4+        | Light multi-instance  |
| 5-8       | 32GB              | 8+        | Medium multi-instance |
| 9+        | 64GB+             | 12+       | Heavy multi-instance  |

## Screen Session Commands

```bash
# List all screen sessions
screen -ls

# Create new screen session
screen -S session_name

# Attach to existing session
screen -r session_name

# Detach from current session
Ctrl+A then D

# Kill a screen session
screen -X -S session_name quit

# View session in read-only mode
screen -x session_name
```
