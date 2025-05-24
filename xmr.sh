#!/bin/bash

# Script to install dependencies, build XMRig, and start mining Monero (XMR) on Ubuntu VPS
# Using 2Miners pool with 0% fee and low minimum payout

# Update and install dependencies
echo "Updating system and installing dependencies..."
sudo apt update
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

# Download latest XMRig source
echo "Downloading XMRig source code..."
cd ~
if [ -d xmrig ]; then
  rm -rf xmrig
fi
git clone https://github.com/xmrig/xmrig.git

# Build XMRig
echo "Building XMRig..."
cd xmrig
mkdir -p build && cd build
cmake ..
make -j$(nproc)

# Check if build succeeded
if [ ! -f xmrig ]; then
  echo "Build failed! Exiting."
  exit 1
fi

# Mining configuration parameters
WALLET_ADDRESS="42g4wYQn7A49tZyjqJwcNAKvNgQDtdmGR3yHGsXF7qVKMRyCeBqLTBBjJh9jL6SGBz1tqGsE7xMBw5P8xJEQGyTJSy6ZkZN"  # Replace with your Monero wallet address
POOL="xmr.2miners.com:1010"
WORKER_NAME="$(hostname)-xmrig"

echo "Starting XMRig mining on 2Miners pool..."
./xmrig --donate-level=1 --max-cpu-usage=100 -o $POOL -u $WALLET_ADDRESS -p $WORKER_NAME --cpu-priority=5
