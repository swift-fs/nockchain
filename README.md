# Nock Node Setup Guide

This guide will help you set up and run Nock nodes (leader and follower) on your system.

## Prerequisites

- Ubuntu 22.04 or similar Linux distribution
- Sudo privileges
- 32-64GB RAM
- At least 200GB free disk space

## Quick Installation

1. **Download the Script**

   ```bash
   curl -sSL https://raw.githubusercontent.com/0xNirvanaByte/nockchain/main/nock.sh -o nock.sh
   chmod +x nock.sh
   ```

2. **Run Commands**

   ```bash
   # Install and build
   ./nock.sh --install

   # Create wallet
   ./nock.sh --createwallet

   # Start leader node (requires mining public key)
   ./nock.sh --startleader

   # Start follower node
   ./nock.sh --startfollower
   ```

## Manual Installation Steps

If you prefer to clone the repository:

1. **Clone the Repository**

   ```bash
   git clone https://github.com/0xNirvanaByte/nockchain.git
   cd nockchain
   ```

2. **Make the Script Executable**

   ```bash
   chmod +x nock.sh
   ```

3. **Install and Build Nock**

   ```bash
   ./nock.sh --install
   ```

   This will:

   - Install all required dependencies
   - Set up Rust toolchain
   - Clone and build the Nockchain repository
   - Configure environment variables

4. **Create a Wallet**

   ```bash
   ./nock.sh --createwallet
   ```

   This will generate:

   - A new wallet
   - Mnemonic phrase
   - Private key
   - Public key

   ⚠️ **IMPORTANT**: Save these credentials securely! You'll need them later.

## Running Nodes

### Leader Node

1. **Start the Leader Node**

   ```bash
   ./nock.sh --startleader
   ```

   The script will:

   - Prompt for your mining public key
   - Update the Makefile with your key
   - Start the leader node in a screen session
   - Begin mining blocks
   - Show logs in real-time

   To detach from the screen session:

   - Press `Ctrl+A` followed by `D`

   To reattach to the screen session:

   ```bash
   screen -r leader-node
   ```

### Follower Node

1. **Start the Follower Node**

   ```bash
   ./nock.sh --startfollower
   ```

   The follower node will:

   - Start in a screen session
   - Connect to the network
   - Show logs in real-time

   To detach from the screen session:

   - Press `Ctrl+A` followed by `D`

   To reattach to the screen session:

   ```bash
   screen -r follower-node
   ```

## Managing Nodes

### Viewing Logs

To view logs for either node:

```bash
# For leader node
screen -r leader-node

# For follower node
screen -r follower-node
```

### Stopping Nodes

To stop a node:

1. Attach to its screen session
2. Press `Ctrl+C` to stop the process
3. Type `exit` to close the screen session

## Troubleshooting

1. **If the installation fails:**

   - Check your internet connection
   - Ensure you have sufficient disk space
   - Verify you have sudo privileges

2. **If the wallet creation fails:**

   - Ensure the installation completed successfully
   - Check if the nockchain-wallet executable exists in the target/release directory

3. **If nodes fail to start:**
   - Check if another instance is already running
   - Verify your system has enough resources
   - Check the logs for specific error messages

## Directory Structure

```
nock/
├── nock.sh           # Main setup and management script
├── README.md         # This documentation
```

## Environment Variables

The script automatically sets up these environment variables:

- `PATH`: Includes the Nockchain binaries
- `RUST_LOG`: Set to "info" for logging
- `MINIMAL_LOG_FORMAT`: Set to "true" for cleaner logs
