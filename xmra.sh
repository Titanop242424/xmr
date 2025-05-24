#!/bin/bash
set -e

# If not run with "run", do setup
if [ "$1" != "run" ]; then
  echo "🔧 Installing dependencies..."
  sudo apt update
  sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

  echo "⬇️ Cloning XMRig..."
  git clone https://github.com/xmrig/xmrig.git

  echo "🛠️ Building XMRig..."
  cd xmrig
  mkdir -p build && cd build
  cmake .. -DWITH_HWLOC=ON
  make -j$(nproc)

  echo "✅ Build finished! Starting miner..."
  exec "$(realpath "$0")" run
fi

# === Start mining ===
WALLET="42g4wYQn7A49tZyjqJwcNAKvNgQDtdmGR3yHGsXF7qVKMRyCeBqLTBBjJh9jL6SGBz1tqGsE7xMBw5P8xJEQGyTJSy6ZkZN"
POOL="pool.supportxmr.com:443"
HOSTNAME="$(hostname)"
NUM_CORES=$(nproc)

echo "⚙️ Detected CPU cores: $NUM_CORES"

cd "$(dirname "$(realpath "$0")")/xmrig/build"

if [ "$NUM_CORES" -ge 2 ]; then
  HALF=$((NUM_CORES / 2))
  CORE_SET1=$(seq -s, 0 $((HALF - 1)) | tr -d ' ')
  CORE_SET2=$(seq -s, $HALF $((NUM_CORES - 1)) | tr -d ' ')

  echo "🚀 Starting Miner #1 on cores: $CORE_SET1"
  taskset -c $CORE_SET1 ./xmrig \
    -o "$POOL" -u "$WALLET" -p "${HOSTNAME}-1" \
    --tls --donate-level=1 --cpu-priority=5 &

  echo "🚀 Starting Miner #2 on cores: $CORE_SET2"
  taskset -c $CORE_SET2 ./xmrig \
    -o "$POOL" -u "$WALLET" -p "${HOSTNAME}-2" \
    --tls --donate-level=1 --cpu-priority=5 &

  wait
else
  echo "🚀 Only 1 core detected, running single miner..."
  ./xmrig \
    -o "$POOL" -u "$WALLET" -p "${HOSTNAME}-solo" \
    --tls --donate-level=1 --cpu-priority=5
fi
