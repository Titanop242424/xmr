#!/bin/bash

# XMRig Installer & Miner Script (Optimized for VPS stealth and performance)
# Pool: SupportXMR (TLS)
# VPS: Ubuntu 20.04/22.04 / Amazon Linux 2023

set -e

echo "🔧 Step 1: Updating system and installing dependencies..."
sudo apt update && sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

echo "⬇️ Step 2: Cloning XMRig repository..."
cd ~
rm -rf xmrig
git clone https://github.com/xmrig/xmrig.git

echo "🛠️ Step 3: Building XMRig..."
cd xmrig
mkdir -p build && cd build
cmake .. -DWITH_HWLOC=ON
make -j$(nproc)

if [ ! -f xmrig ]; then
  echo "❌ Build failed! Exiting."
  exit 1
fi

echo "✅ Build successful!"

# === Configuration ===
WALLET_ADDRESS="42g4wYQn7A49tZyjqJwcNAKvNgQDtdmGR3yHGsXF7qVKMRyCeBqLTBBjJh9jL6SGBz1tqGsE7xMBw5P8xJEQGyTJSy6ZkZN"
POOL="pool.supportxmr.com:443"
WORKER_NAME="$(hostname)-xmrig"

# Validate wallet length
if [[ ${#WALLET_ADDRESS} -lt 90 ]]; then
  echo "⚠️ Wallet address might be invalid (length too short)"
fi

# === Optimize stealth ===
CPU_CORES=$(nproc)
XMRIG_BIN=~/xmrig/build/xmrig

echo "📊 CPU cores detected: $CPU_CORES"

# Optional random delay before starting to avoid automation detection
RANDOM_DELAY=$((RANDOM % 30 + 10))
echo "⏳ Sleeping for $RANDOM_DELAY seconds to randomize startup..."
sleep $RANDOM_DELAY

# === Recommended flags for stealth ===
# - max-cpu-usage: 85% to reduce throttling suspicion
# - cpu-priority: 0 (lowest)
# - background: true (optional)
# - print-time: 60 (reduce log frequency)
# - tls-fingerprint: safe custom one (less common)

echo "🚀 Starting optimized XMRig miner..."

"$XMRIG_BIN" \
  --donate-level=1 \
  --max-cpu-usage=85 \
  --cpu-priority=0 \
  --print-time=60 \
  --tls \
  -o "$POOL" \
  -u "$WALLET_ADDRESS" \
  -p "$WORKER_NAME" \
  --tls-fingerprint=auto \
  --background
