#!/bin/bash

# XMRig Installer & Miner Script for Ubuntu (SupportXMR pool with TLS)
# Optimized for high CPU usage

set -e

echo "🔧 Step 1: Updating system and installing dependencies..."
sudo apt update && sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

echo "⬇️ Step 2: Cloning XMRig repository..."
cd "$HOME"
rm -rf xmrig
git clone https://github.com/xmrig/xmrig.git

echo "🛠 Step 3: Building XMRig (optimized)..."
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
WALLET_ADDRESS="43ihxdg6U74LfU1aYnB2f3W6bMtNpkrBLPuhDUJT2QYJ87ax8jxuHUPDad4fH2UmcK9YJah5wjJCmS7cMoFf8zkF7e5ArBb"
POOL="gulf.moneroocean.stream:10128"
WORKER_NAME="$(hostname)-xmrig"
WORKDIR="$HOME/xmrig"

# Optional: Wallet validation
if [[ ${#WALLET_ADDRESS} -lt 90 ]]; then
  echo "⚠️ Warning: Your wallet address appears to be too short. Please double-check it."
fi

echo "🚀 Step 4: Starting XMRig miner on SupportXMR (TLS enabled)..."

cd "$WORKDIR/build"
taskset -a -c 0-$(($(nproc) - 1)) ./xmrig \
  --max-cpu-usage=100 \
  --cpu-priority=1 \
  -o "$POOL" \
  -u "$WALLET_ADDRESS" \
  -p "$WORKER_NAME" \
  --tls
