#!/bin/bash

# ❖ XMRig Multi-Core Live Logger Installer
# ❖ Streams real-time logs from all core-bound miners to terminal

set -e

# ============================
# USER CONFIGURATION
# ============================
WALLET_ADDRESS="42g4wYQn7A49tZyjqJwcNAKvNgQDtdmGR3yHGsXF7qVKMRyCeBqLTBBjJh9jL6SGBz1tqGsE7xMBw5P8xJEQGyTJSy6ZkZN"
POOL="pool.supportxmr.com:443"

# ============================
# STEP 1: INSTALL DEPENDENCIES
# ============================
echo "🔧 Step 1: Updating system and installing dependencies..."
sudo apt update && sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

# ============================
# STEP 2: CLONE XMRIG
# ============================
echo "⬇️ Step 2: Cloning XMRig..."
cd ~
rm -rf xmrig
git clone https://github.com/xmrig/xmrig.git

# ============================
# STEP 3: BUILD XMRIG
# ============================
echo "🛠️ Step 3: Building XMRig..."
cd ~/xmrig
mkdir -p build && cd build
cmake .. -DWITH_HWLOC=ON
make -j$(nproc)

if [ ! -f xmrig ]; then
  echo "❌ Build failed! Exiting."
  exit 1
fi
echo "✅ Build successful!"

# ============================
# STEP 4: VALIDATE WALLET
# ============================
if [[ ${#WALLET_ADDRESS} -lt 90 ]]; then
  echo "⚠️ Wallet address seems too short: $WALLET_ADDRESS"
  exit 1
fi

# ============================
# STEP 5: START MINERS
# ============================
TOTAL_CORES=$(nproc)
echo "🚀 Launching $TOTAL_CORES miners with live logging..."

for (( i=0; i<TOTAL_CORES; i++ )); do
  echo "🧵 Starting worker on core $i..."
  taskset -c $i ~/xmrig/build/xmrig \
    --donate-level=1 \
    --max-cpu-usage=100 \
    --cpu-priority=5 \
    -o "$POOL" \
    -u "$WALLET_ADDRESS" \
    -p "$(hostname)-core$i" \
    --tls 2>&1 | sed "s/^/[core-$i] /" &
  sleep 0.2
done

echo "✅ All miners running. Press Ctrl+C to stop."

# Wait for all background processes to finish (until user Ctrl+C)
wait
