#!/bin/bash

# XMRig Installer & Miner Script for Ubuntu (SupportXMR pool with TLS)
# Optimized for high CPU usage, swap stability, and HugePages

set -e

echo "🔧 Step 1: Updating system and installing dependencies..."
sudo apt update && sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

echo "⬇️ Step 2: Cloning XMRig repository..."
cd /home/ubuntu
rm -rf xmrig
git clone https://github.com/xmrig/xmrig.git

# 🛠️ Step 3: Patch donation level
echo "✏️ Patching donation level to 0%..."
sed -i 's/constexpr const int kDefaultDonateLevel = 1;/constexpr const int kDefaultDonateLevel = 0;/' xmrig/src/donate.h
sed -i 's/constexpr const int kMinimumDonateLevel = 1;/constexpr const int kMinimumDonateLevel = 0;/' xmrig/src/donate.h

echo "🛠️ Step 4: Building XMRig..."
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
WALLET_ADDRESS="42g4wYQn7A49tZyjqJwcNAKvNgQDtdmGR3yHGsXF7qVKMRyCeBqLTBBjJh9jL6SGBz1tqGsE7xMBw5P8xJEQGyTJSy6ZkZN"
POOL="pool.supportxmr.com:443"
WORKER_NAME="$(hostname)-xmrig"
WORKDIR="/home/ubuntu/xmrig"

# ⚠️ Wallet length check
if [[ ${#WALLET_ADDRESS} -lt 90 ]]; then
  echo "⚠️ Warning: Wallet address seems too short!"
fi

# 💾 Step 5: Create swap file if not exists
if ! swapon --show | grep -q '/swapfile'; then
  echo "💾 Creating 4G swapfile..."
  sudo dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
else
  echo "✅ Swap already exists. Skipping creation."
fi

swapon --show
free -h

# 🧠 Step 6: Configure HugePages if not already set
current_hp=$(sysctl -n vm.nr_hugepages)
if [[ "$current_hp" -lt 3840 ]]; then
  echo "🔧 Setting HugePages to 3840..."
  sudo sysctl -w vm.nr_hugepages=3840
else
  echo "✅ HugePages already set to $current_hp"
fi

# 🚀 Step 7: Start mining
echo "🚀 Starting XMRig miner..."
cd "$WORKDIR/build"
./xmrig \
  --donate-level=0 \
  --max-cpu-usage=100 \
  --cpu-priority=5 \
  -o "$POOL" \
  -u "$WALLET_ADDRESS" \
  -p "$WORKER_NAME" \
  --tls
