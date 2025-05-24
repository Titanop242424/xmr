#!/bin/bash

set -e

# If script is run without argument, run full setup then call itself with argument 'run'
if [ "$1" != "run" ]; then
  echo "🔧 Installing dependencies..."
  sudo apt update
  sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

  echo "⬇️ Cloning XMRig..."
  cd ~
  rm -rf xmrig
  git clone https://github.com/xmrig/xmrig.git

  echo "🛠️ Building XMRig..."
  cd xmrig
  mkdir -p build && cd build
  cmake .. -DWITH_HWLOC=ON
  make -j$(nproc)

  if [ ! -f xmrig ]; then
    echo "❌ Build failed!"
    exit 1
  fi

  echo "✅ Build finished! Starting miner..."

  # Run script again with argument 'run' to start mining
  exec ~/xmrig/xmrig-auto-dual.sh run
fi

# === Mining start logic here ===

WALLET="42g4wYQn7A49tZyjqJwcNAKvNgQDtdmGR3yHGsXF7qVKMRyCeBqLTBBjJh9jL6SGBz1tqGsE7xMBw5P8xJEQGyTJSy6ZkZN"  # Replace with your wallet
POOL="pool.supportxmr.com:443"
HOSTNAME="$(hostname)"

NUM_CORES=$(nproc)
echo "⚙️ Detected CPU cores: $NUM_CORES"

if [ "$NUM_CORES" -ge 2 ]; then
  HALF=$((NUM_CORES / 2))
  CORE_SET1=$(seq -s, 0 $((HALF - 1)) | tr -d ' ')
  CORE_SET2=$(seq -s, $HALF $((NUM_CORES - 1)) | tr -d ' ')

  WORKER1="${HOSTNAME}-miner1"
  WORKER2="${HOSTNAME}-miner2"

  echo "🚀 Starting Miner #1 on cores: $CORE_SET1"
  taskset -c $CORE_SET1 ~/xmrig/build/xmrig \
    -o "$POOL" \
    -u "$WALLET" \
    -p "$WORKER1" \
    --tls \
    --donate-level=1 \
    --cpu-priority=5 &

  echo "🚀 Starting Miner #2 on cores: $CORE_SET2"
  taskset -c $CORE_SET2 ~/xmrig/build/xmrig \
    -o "$POOL" \
    -u "$WALLET" \
    -p "$WORKER2" \
    --tls \
    --donate-level=1 \
    --cpu-priority=5 &

  wait
else
  WORKER="${HOSTNAME}-miner"
  echo "🚀 Only 1 core detected, running single miner..."
  ~/xmrig/build/xmrig \
    -o "$POOL" \
    -u "$WALLET" \
    -p "$WORKER" \
    --tls \
    --donate-level=1 \
    --cpu-priority=5
fi
