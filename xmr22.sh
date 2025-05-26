#!/bin/bash

# XMRig Installer & Miner Script for Ubuntu (SupportXMR pool with TLS)
# Optimized for high CPU usage

set -e

echo "🔧 Step 1: Updating system and installing dependencies..."
sudo apt update && sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev screen

echo "⬇️ Step 2: Cloning XMRig repository..."
cd "$HOME"
rm -rf xmrig
git clone https://github.com/xmrig/xmrig.git

echo "🛠️ Step 3: Building XMRig (optimized)..."
cd xmrig
mkdir -p build && cd build
cmake .. -DWITH_HWLOC=ON -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

if [ ! -f xmrig ]; then
  echo "❌ Build failed! Exiting."
  exit 1
fi

echo "✅ Build successful!"

# === Configuration ===
WALLET_ADDRESS="42g4wYQn7A49tZyjqJwcNAKvNgQDtdmGR3yHGsXF7qVKMRyCeBqLTBBjJh9jL6SGBz1tqGsE7xMBw5P8xJEQGyTJSy6ZkZN"  # Replace with your Monero wallet
POOL="pool.supportxmr.com:443"
WORKER_NAME="$(hostname)-xmrig"
WORKDIR="/home/user/xmrig"

# Optional: Wallet validation
if [[ ${#WALLET_ADDRESS} -lt 90 ]]; then
  echo "⚠️ Warning: Your wallet address appears to be too short. Please double-check it."
fi

echo "🚀 Step 4: Starting XMRig miner in a screen session (TLS enabled, full CPU)..."

# Kill existing screen session if it exists
screen -S xmrig -X quit 2>/dev/null || true

# Start a new detached screen session running XMRig
screen -dmS xmrig "$WORKDIR/build/xmrig" \
  --donate-level=1 \
  --max-cpu-usage=100 \
  --cpu-priority=5 \
  --threads=$(nproc) \
  -o "$POOL" \
  -u "$WALLET_ADDRESS" \
  -p "$WORKER_NAME" \
  --tls

echo "✅ Miner launched! Use 'screen -r xmrig' to view it."
