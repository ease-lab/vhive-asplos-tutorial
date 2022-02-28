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

Then you can use the single node setup script to set up the environment
```
cd ~/vhive/
./scripts/cloudlab/setup_node.sh
```

Expected errors:
```
sysctl: setting key "net.ipv4.conf.all.promote_secondaries": Invalid argument
fatal: destination path '/home/vhive-user/client' already exists and is not an empty directory.
device-mapper: reload ioctl on fc-dev-thinpool  failed: No such device or address
Command failed.
```

We start the basic containerd that we will use to run infrastructure
containers.

```
sudo screen -dmS containerd containerd; sleep 5;
```

We start the firecracker containerd that will run the functions.

```
sudo PATH=$PATH screen -dmS firecracker /usr/local/bin/firecracker-containerd --config /etc/firecracker-containerd/config.toml; sleep 5;
```

After we confirmed that both of them are running using `sudo screen -ls` we can
build and start the vHive CRI using:

```
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

There should be three running pods for istio-system, seven running pods for
knative-eventing, eight running and one completed for knative-serving,
nine running for kube-system and two running each for metallb-system and
registry.

### Deploy and Invoke

With the running single node cluster we can first deploy a single hello world
function.

```
./examples/deployer/deployer -jsonFile ~/singleFunction.json -endpointsFile ~/singleEndpoint.json
```
After deployment we can check if the service is ok with
```
kn services list
```
The output of this command should show a single service called helloworld-0
and its properties.
Then we can invoke the service using the invoker:

```
./examples/invoker/invoker -rps 1 -time 10 -endpointsFile ~/singleEndpoint.json -latf singleFunction
```

It can be that you don't get the same amount of issued and completed requests.
This is due to time outs when having cold starts.
In this case rerun the invoker.

To get a better understanding of how the tools work and the cluster behaves
differently under different load we now deploy and run 3 hello world functions
and one function performing AES.

```
./examples/deployer/deployer -jsonFile ~/twoFunctions.json -endpointsFile ~/multipleEndpoints.json
kn service list
./examples/invoker/invoker -rps 4 -time 10 -endpointsFile ~/multipleEndpoints.json -latf multipleFunctions
```
The service list should show four services, helloworld-0, helloworld-1,
helloworld-2 and payes-0.

Lastly we enable snapshots to show how latencies change with faster cold starts.
The tear down and restarting with snapshots can be done using a script:
```
export GITHUB_VHIVE_ARGS="[-snapshots]"
./scripts/cloudlab/start_onenode_vhive_cluster.sh
```

Then we can repeat the four function measurements with the new set up and
observe the differences in latencies.

```
./examples/deployer/deployer -jsonFile ~/twoFunctions.json -endpointsFile ~/multipleEndpoints.json
kn service list
./examples/invoker/invoker -rps 4 -time 10 -endpointsFile ~/multipleEndpoints.json -latf multipleFunctionSnapshot
```

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
```
Expected errors:
```
sysctl: setting key "net.ipv4.conf.all.promote_secondaries": Invalid argument
fatal: destination path '/home/vhive-user/client' already exists and is not an empty directory.
device-mapper: remove ioctl on fc-dev-thinpool  failed: No such device or address
Command failed.
```

After this you can check the running pods again with `kubectl get pods -A`.
It should have the same pods running and completed as before.

Then we can start zipkin to start collecting telemetry data.

```
./scripts/setup_zipkin.sh
screen -dmS zipkin bash -c 'source /etc/profile; istioctl dashboard zipkin'
```
You can check that zipkin dashboard is running with `screen -ls`.

Then we can deploy the functions to run the video analytics with a single frame:
```
export AWS_ACCESS_KEY=<YOUR_KEY>
export AWS_SECRET_KEY=<YOUR_SECRET>
export BUCKET_NAME=<BUCKET NAME>
export ENABLE_TRACING=”true”
~/vSwarm/tools/kn_deploy.sh ~/vSwarm/benchmarks/video-analytics/knative_yamls/s3_single/*
```

After that we can check if everything is running using `kn service list`.
You should see three services named decoder recog and streaming.
From that we need the address of the streaming service.

To invoke it we need the URL without the `https://`

```
~/vSwarm/tools/test-client/test-client -addr <address>:80
```
As a result you should get a list of objects.
Then you can look at the Zipkin UI in your browser on `localhost:9411`
In Zipkin you should see a magnifying glass on the left to get to the search.
On the top left you can click the plus to add a filter.
Choose service name and recog to filter for traces that contain the recognition
service.
With the magnifying glass on the right you can start the search.
You should see one result which you can click to expand.
The expanded result will show all the parts that the trace went through.

After that we can delete the services and redeploy with decoding set to 6
images.
Then invoke it again using the test client.

```
kn service delete --all
~/vSwarm/tools/kn_deploy.sh ~/vSwarm/benchmarks/video-analytics/knative_yamls/s3/*
kn service list
~/vSwarm/tools/test-client/test-client -addr <address>:80
```

Use the same search in Zipkin as before.
This time there will be two traces found, click on the newer one.
In this trace you will see that the recognition task is called 6 times in
sequence.

## Clean-up

Tear down any remaining clusters.

```
./scripts/github_runner/clean_cri_runner.sh
```
