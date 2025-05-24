#!/bin/bash

# Set working directory
WORKDIR="/home/ubuntu/xmrig"

# Step 1: Create 8 GB swap (if not already 8 GB)
echo "💾 Checking swap memory..."
CURRENT_SWAP=$(free -g | awk '/Swap:/ {print $2}')
if [ "$CURRENT_SWAP" -lt 8 ]; then
    echo "📦 Creating 8 GB swap file..."
    sudo swapoff -a
    sudo rm -f /swapfile
    sudo fallocate -l 8G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1G count=8
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
else
    echo "💾 Swap memory already 8 GB or more, skipping swap setup."
fi

# Step 2: Clone XMRig
echo "⬇️ Step 2: Cloning XMRig..."
mkdir -p "$WORKDIR"
cd /home/ubuntu
rm -rf "$WORKDIR"
git clone https://github.com/xmrig/xmrig.git "$WORKDIR"

# Step 3: Build XMRig
echo "🛠️ Step 3: Building XMRig..."
cd "$WORKDIR"
mkdir -p build
cd build
cmake .. -DWITH_HWLOC=ON
make -j$(nproc)

# Step 4: Launch 4 workers using 4 cores in screen
echo "🚀 Launching 4 miners bound to cores..."
screen -dmS xmrig-miners bash -c '
for (( i=0; i<4; i++ )); do
  echo "🧵 Starting worker $i bound to core $i..."
  taskset -c $i '"$WORKDIR"'/build/xmrig \
    --donate-level=1 \
    --max-cpu-usage=100 \
    --cpu-priority=5 \
    -o pool.supportxmr.com:443 \
    -u 42g4wYQn7A49tZyjqJwcNAKvNgQDtdmGR3yHGsXF7qVKMRyCeBqLTBBjJh9jL6SGBz1tqGsE7xMBw5P8xJEQGyTJSy6ZkZN \
    -p '"$(hostname)"'-core$i \
    --tls 2>&1 | sed "s/^/[core-$i] /" &
  sleep 0.3
done
wait
'

echo "✅ All miners launched inside a screen session called 'xmrig-miners'."
echo "👉 Run 'screen -r xmrig-miners' to view logs or Ctrl+A+D to detach."
