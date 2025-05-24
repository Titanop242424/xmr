#!/bin/bash

# ❖ XMRig Multi-Core Live Logger Installer with 4 Workers & 8GB Swap + screen install

set -e

# ============================
# USER CONFIGURATION
# ============================
WALLET_ADDRESS="42g4wYQn7A49tZyjqJwcNAKvNgQDtdmGR3yHGsXF7qVKMRyCeBqLTBBjJh9jL6SGBz1tqGsE7xMBw5P8xJEQGyTJSy6ZkZN"
POOL="pool.supportxmr.com:443"
WORKERS=4          # number of miner workers to run
SWAPSIZE_GB=8      # swap size in GB

# ============================
# STEP 1: UPDATE, INSTALL DEPENDENCIES & SCREEN
# ============================
echo "🔧 Step 1: Updating system and installing dependencies + screen..."
sudo apt update
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev screen

# ============================
# STEP 2: SETUP SWAP MEMORY
# ============================
# Check if swap already exists
if free | grep -q "Swap: *0B"; then
  echo "💾 Setting up ${SWAPSIZE_GB}GB swap file..."
  sudo fallocate -l ${SWAPSIZE_GB}G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
else
  echo "💾 Swap memory already present, skipping swap setup."
fi

# ============================
# STEP 3: CLONE XMRIG
# ============================
echo "⬇️ Step 2: Cloning XMRig..."
cd ~
rm -rf xmrig
git clone https://github.com/xmrig/xmrig.git

# ============================
# STEP 4: BUILD XMRIG
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
# STEP 5: VALIDATE WALLET
# ============================
if [[ ${#WALLET_ADDRESS} -lt 90 ]]; then
  echo "⚠️ Wallet address seems too short: $WALLET_ADDRESS"
  exit 1
fi

# ============================
# STEP 6: START MINERS (4 workers bound to cores)
# ============================
TOTAL_CORES=$(nproc)

echo "🚀 Launching $WORKERS miners bound to cores..."

for (( i=0; i<WORKERS; i++ )); do
  CORE=$(( i % TOTAL_CORES ))   # cycle cores if workers > cores
  echo "🧵 Starting worker $i bound to core $CORE..."
  taskset -c $CORE ~/xmrig/build/xmrig \
    --donate-level=1 \
    --max-cpu-usage=100 \
    --cpu-priority=5 \
    -o "$POOL" \
    -u "$WALLET_ADDRESS" \
    -p "$(hostname)-core$i" \
    --tls 2>&1 | sed "s/^/[core-$i] /" &
  sleep 0.2
done

echo "✅ All miners running. Use 'screen -r' to access screen sessions or Ctrl+C to stop."

# Wait for all miners to run (until Ctrl+C)
wait
