#!/bin/bash

# XMRig Installer & Miner Script for Ubuntu (SupportXMR pool with TLS)
# Optimized for high CPU usage and performance tuning

set -e

echo "🔧 Step 1: Updating system and installing dependencies..."
sudo apt update && sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

echo "⬇️ Step 2: Cloning XMRig repository..."
cd /home/ubuntu
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
WORKDIR="/home/ubuntu/xmrig"

# Wallet sanity check
if [[ ${#WALLET_ADDRESS} -lt 90 ]]; then
  echo "⚠️ Warning: Your wallet address appears to be too short. Please double-check it."
fi

# === Step 4: Create 4GB swapfile ===
echo "💾 Creating 4G swapfile for stability..."
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
swapon --show
free -h

# === Step 5: Enable Huge Pages ===
echo "📄 Setting hugepages for mining performance..."
sudo sysctl -w vm.nr_hugepages=3840

# === Step 6: Start XMRig Miner ===
echo "🚀 Starting XMRig miner on SupportXMR with TLS..."

cd "$WORKDIR/build"
taskset -a -c 0-$(($(nproc) - 1)) ./xmrig \
  --max-cpu-usage=100 \
  --cpu-priority=5 \
  -o "$POOL" \
  -u "$WALLET_ADDRESS" \
  -p "$WORKER_NAME" \
  --tls

# ❌ Removed screen section as per your request
