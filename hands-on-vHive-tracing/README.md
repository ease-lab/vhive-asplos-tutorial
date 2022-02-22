# vHive Tracing

## Setup

Machine Setup:

```
gcloud compute instances create <VM-name> --project=vhive-tutorial --zone=us-west2-a --machine-type=n1-standard-4 --enable-nested-virtualization --scopes=https://www.googleapis.com/auth/cloud-platform --tags=http-server,https-server --create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/vhive-tutorial/global/images/vhive-tracing,mode=rw,size=100,type=projects/vhive-tutorial/zones/us-central1-a/diskTypes/pd-balanced
```

These instructions have already been performed on the VMs you are handed.
If you want to replicate it later on set up your machine with the following:

clone vHive and vSwarm:
```
git clone https://github.com/ease-lab/vhive.git
git clone https://github.com/ease-lab/vSwarm.git
```
Then you can use the single node setup script
```
cd ~/vhive/
./scripts/cloudlab/setup_node.sh
```

And build all executables
```
source /etc/profile
cd ~/vhive/
go build
cd ~/vhive/examples/deployer/
go build
cd ~/vhive/examples/invoker/
go build
cd ~/vSwarm/tools/test-client/
go build
```

## Steps

### Single Node Cluster Start
After setting up the node we need to start the different parts in the correct
order. If you are not logged into the VM yet, you can use the following command:

```
ssh -i <path-to-key> -L 9411:127.0.0.1:9411 vhive-user@<IP>
```

First we start the basic containerd that we will use to run infrastructure
containers.

```
sudo screen -dmS containerd containerd; sleep 5;
```

Then we start the firecracker containerd that will run the functions.

```
sudo PATH=$PATH screen -dmS firecracker /usr/local/bin/firecracker-containerd --config /etc/firecracker-containerd/config.toml; sleep 5;
```

After we confirmed that both of them are running using `sudo screen -ls` we can
build and start the vHive CRI using:

```
cd ~/vhive/
sudo screen -dmS vhive ./vhive; sleep 5;
```

After this also is done we can check again with `sudo screen -ls` and then use
a script to set up the remaining parts of the infrastructure.

```
./scripts/cluster/create_one_node_cluster.sh
```

Check that everything is up and running with:

```
kubectl get pods -A
```

### Deploy and Invoke

With the running single node cluster we can first deploy a single hello world
function.

```
cd ~/vhive/
./examples/deployer/deployer -jsonFile ~/singleFunction.json -endpointsFile ~/singleEndpoint.json
```
After deployment is finished we can start invoking it.

```
./examples/invoker/invoker -rps 1 -time 10 -endpointsFile ~/singleEndpoint.json -latf singleFunction
```

To get a better understanding of how the tools work and the cluster behaves
differently under different load we now deploy and run 3 hello world functions
and one function performing AES.

```
./examples/deployer/deployer -jsonFile ~/twoFunctions.json -endpointsFile ~/multipleEndpoints.json
./examples/invoker/invoker -rps 4 -time 10 -endpointsFile ~/multipleEndpoints.json -latf multipleFunctions
```

Lastly we enable snapshots to show how latencies change with faster cold starts.
The tear down and restarting with snapshots can be done using a script:
```
export GITHUB_VHIVE_ARGS="[-snapshots] [-upf]"
scripts/cloudlab/start_onenode_vhive_cluster.sh
```

Then we can repeat the four function measurements with the new set up and
observe the differences in latencies.

After that we can tear down the cluster.
```
./scripts/github_runner/clean_cri_runner.sh
```

### Tracing

To go over to tracing we switch to stock knative setup, meaning we will only
user normal containerd to simplify the traces.
Additionally we want to set up a zipkin dashboard that collects data for the
traces. To set this up we run:
```
./scripts/cloudlab/setup_node.sh stock-only
sudo screen -dmS containerd containerd; sleep 5;
./scripts/cluster/create_one_node_cluster.sh stock-only
./scripts/setup_zipkin.sh
screen -dmS zipkin istioctl dashboard zipkin
```
Then we can deploy the functions to run the video analytics:
```
export AWS_ACCESS_KEY=<YOUR_KEY>
export AWS_SECRET_KEY=<YOUR_SECRET>
export ENABLE_TRACING=”true”
~/vSwarm/tools/kn_deploy.sh ~/vSwarm/benchmarks/video-analytics/knative_yamls/s3/*
```

After that we can check if everything is running using `kn services list`.
From that we need the address of the streaming service.

To invoke it we need the URL without the `https://`

```
~/vSwarm/tools/test-client
```

## Clean-up

Tear down any remaining clusters.

```
./scripts/github_runner/clean_cri_runner.sh
```
