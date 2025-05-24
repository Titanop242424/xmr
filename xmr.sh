#!/bin/bash

# XMRig Installer & Miner Script for Ubuntu (SupportXMR pool with TLS)
# Tested on Ubuntu 20.04/22.04 and Amazon Linux 2023

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
WALLET_ADDRESS="42g4wYQn7A49tZyjqJwcNAKvNgQDtdmGR3yHGsXF7qVKMRyCeBqLTBBjJh9jL6SGBz1tqGsE7xMBw5P8xJEQGyTJSy6ZkZN"  # Replace with your Monero wallet
POOL="pool.supportxmr.com:443"
WORKER_BASE="$(hostname)-xmrig"

# Optional: Wallet validation
if [[ ${#WALLET_ADDRESS} -lt 90 ]]; then
  echo "⚠️ Warning: Your wallet address appears to be too short. Please double-check it."
fi

echo "📊 Detecting CPU cores..."
TOTAL_CORES=$(nproc)
echo "🧠 Total CPU cores available: $TOTAL_CORES"

XMRIG_BIN=~/xmrig/build/xmrig

if [ "$TOTAL_CORES" -ge 2 ]; then
  HALF=$((TOTAL_CORES / 2))
  CORE_SET1=$(seq -s, 0 $((HALF - 1)) | tr -d ' ')
  CORE_SET2=$(seq -s, $HALF $((TOTAL_CORES - 1)) | tr -d ' ')

  echo "🚀 Starting Miner #1 on cores: $CORE_SET1"
  taskset -c $CORE_SET1 "$XMRIG_BIN" \
    --donate-level=1 \
    --max-cpu-usage=100 \
    --cpu-priority=5 \
    -o "$POOL" \
    -u "$WALLET_ADDRESS" \
    -p "${WORKER_BASE}-1" \
    --tls &

  echo "🚀 Starting Miner #2 on cores: $CORE_SET2"
  taskset -c $CORE_SET2 "$XMRIG_BIN" \
    --donate-level=1 \
    --max-cpu-usage=100 \
    --cpu-priority=5 \
    -o "$POOL" \
    -u "$WALLET_ADDRESS" \
    -p "${WORKER_BASE}-2" \
    --tls &

  wait
else
  echo "🚀 Only 1 CPU core detected. Running a single miner..."
  "$XMRIG_BIN" \
    --donate-level=1 \
    --max-cpu-usage=100 \
    --cpu-priority=5 \
    -o "$POOL" \
    -u "$WALLET_ADDRESS" \
    -p "${WORKER_BASE}-solo" \
    --tls
fi
