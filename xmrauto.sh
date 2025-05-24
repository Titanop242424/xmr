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
WALLET_ADDRESS="42g4wYQn7A49tZyjqJwcNAKvNgQDtdmGR3yHGsXF7qVKMRyCeBqLTBBjJh9jL6SGBz1tqGsE7xMBw5P8xJEQGyTJSy6ZkZN"  # Replace with your Monero wallet address
POOL="pool.supportxmr.com:443"
TOTAL_CORES=$(nproc)

# Optional: Wallet validation
if [[ ${#WALLET_ADDRESS} -lt 90 ]]; then
  echo "⚠️ Warning: Your wallet address appears to be too short. Please double-check it."
fi

echo "🚀 Step 4: Starting XMRig miner(s)..."

if [[ $TOTAL_CORES -lt 2 ]]; then
  echo "⚙️ Only $TOTAL_CORES core detected. Starting single XMRig instance..."
  ~/xmrig/build/xmrig \
    --donate-level=1 \
    --max-cpu-usage=100 \
    --cpu-priority=5 \
    -o "$POOL" \
    -u "$WALLET_ADDRESS" \
    -p "$(hostname)-xmrig" \
    --tls
else
  echo "⚙️ $TOTAL_CORES cores detected. Launching one XMRig instance per core..."
  for (( i=0; i<TOTAL_CORES; i++ )); do
    echo "🧵 Starting worker $i on core $i..."
    taskset -c $i ~/xmrig/build/xmrig \
      --donate-level=1 \
      --max-cpu-usage=100 \
      --cpu-priority=5 \
      -o "$POOL" \
      -u "$WALLET_ADDRESS" \
      -p "$(hostname)-core$i" \
      --tls > ~/xmrig_worker_$i.log 2>&1 &
    sleep 1
  done
  echo "✅ All workers started in the background. Logs: ~/xmrig_worker_*.log"
fi
