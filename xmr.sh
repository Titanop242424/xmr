#!/bin/bash

# ======================================================================
# Setup script to install dependencies, build and run XMRig miner on Amazon Linux
# by BLACKBOXAI
# Usage:
#   1. Update the WALLET_ADDRESS variable to your Monero wallet address.
#   2. Run: bash setup_xmrig.sh
#
# This script installs necessary dependencies (hwloc, libuv, openssl, git, cmake),
# clones the xmrig repository, builds it, and starts mining Monero using recommended settings.
# ======================================================================

# === User configurable variables ===
WALLET_ADDRESS="YOUR_MONERO_WALLET_ADDRESS_HERE"
POOL="pool.minexmr.com:4444"
WORKER_NAME="amazon-linux-vps"
THREADS=$(nproc)  # use all available CPU threads

# Exit immediately if a command exits with a non-zero status
set -e

echo "===== Updating system packages ====="
sudo yum update -y

echo "===== Installing development tools and libraries ====="
sudo yum groupinstall "Development Tools" -y
sudo yum install -y git cmake make gcc-c++ hwloc hwloc-devel libuv libuv-devel openssl openssl-devel

echo "===== Cloning XMRig repository ====="
if [ ! -d "xmrig" ]; then
  git clone https://github.com/xmrig/xmrig.git
else
  echo "xmrig directory already exists. Skipping clone."
fi

echo "===== Building XMRig ====="
cd xmrig
mkdir -p build
cd build
cmake ..
make -j$(nproc)

echo "===== Starting XMRig miner ====="
# Run xmrig with:
# - pool address
# - user wallet address
# - worker name for mining pool identification
# - donate-level 1 to keep miner support
# - tuned for CPU mining (threads, CPU affinity auto)
./xmrig -o $POOL -u $WALLET_ADDRESS -p $WORKER_NAME -k --coin monero --donate-level 1 --threads=$THREADS

# Note: The miner will keep running in the terminal. To stop, press Ctrl+C.
