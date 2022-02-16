#!/usr/bin/env bash
git clone --depth=1 https://github.com/ease-lab/vhive.git
cd vhive

./scripts/cloudlab/setup_node.sh

tmux new -s containerd -d
tmux send -t containerd 'sudo containerd 2>&1 | tee ~/containerd_log.txt' ENTER
sleep 5;

tmux new -s firecracker -d
tmux send -t firecracker "sudo PATH=$PATH /usr/local/bin/firecracker-containerd --config /etc/firecracker-containerd/config.toml 2>&1 | tee ~/firecracker_log.txt" ENTER

source /etc/profile && go build;

tmux new -s vhive -d
tmux send -t vhive 'sudo ./vhive 2>&1 | tee ~/vhive_log.txt' ENTER
sleep 5;

./scripts/cluster/create_one_node_cluster.sh

exec bash
cd