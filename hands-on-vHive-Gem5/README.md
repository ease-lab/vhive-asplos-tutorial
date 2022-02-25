# Microarchitectural Research

## Setup

In order to simulate containerized functions in using gem5 several steps need to be done before your first experiments.
Due to time limits and long compile time we provide you with a gcp image where everything is already preinstalled and ready to start your microarchitectual research.

We created a separate hands on [here](setup.md) where you can find all instructions how to setup the whole stack by your own.

## Steps

1. Start your disk image and setup your custom containerized function using `qemu`
2. Boot your disk image and take a snapshot with `kvm`
3. Measure IPC of your function


### 1. Start your disk image and setup your function
Before running the simulator you need to setup your containerized function onto the disk image.
For this we will use the qemu emulator as it faster and has access to the internet for pulling the image. Run the long command for qemu in the script `run_qemu.sh`.
<!-- ```bash
DISK_IMG=workload/disk-image.img
KERNEL=workload/vmlinux
RAM=8G
CPUS=4

sudo qemu-system-x86_64 \
    -nographic \
    -cpu host -enable-kvm \
    -smp ${CPUS} \
    -m ${RAM} \
    -device e1000,netdev=net0 \
    -netdev type=user,id=net0,hostfwd=tcp:127.0.0.1:5555-:22  \
    -drive format=raw,file=$DISK_IMG \
    -kernel $KERNEL \
    -append 'earlyprintk=ttyS0 console=ttyS0 lpj=7999923 root=/dev/hda2'
``` -->

```
./scripts/run_qemu.sh
```
Qemu will boot with the disk image and the kernel we provided for you in the workload folder.
As soon as the system is booted you can login as root (password `root`). To setup and test the function you want to investigate with the simulator we nee. We will use the `aes-go` function as example.

1. Pull and start the container.
```bash
# Pull your containerized function image
docker pull davidschall/aes-go
# Start your function container
# -d detaches the process and we can continue in the same console.
# -p must be set to export the ports
docker run -d --name mycontainer -p 50051:50051 davidschall/aes-go
```
2. The container is running ans we want to test if everything is fine on the software side. For this we added for you a very small client in the disk image.
   > Note you can find the source code of the client together with your hands out material.
```bash
# run the client with the port you export in docker as well as the number of invocations you want to run.
# -addr is the address and port we where exporting with the docker command
# -n is the number of invocations the client should perform
./client -addr localhost:50051 -n 100
```
3. The client should print its progress after every 10 invocations.

Now the disk image is ready for the Gem5 simulator. Stop the container and shutdown qemu.
```
docker stop mycontainer && docker rm mycontainer
shutdown -h now
```
> Note: Qemu breaks the line wrapping you might want to reset the console by executing `reset`.

### 2. Start your disk image with the gem5 simulator.
To run gem5 we need in addition to the kernel and disk image a config file. This config file defines the system to be simulated.
We provided an example setup for you in the `gem5-configs/` folder.
This consists of a dual core CPU a common LLC and a 2GB memory.
We run the linux OS exclusively on core 0 and we will pin our function container to core 1. With that we can measure our function without any intervention from the OS.

In addition we need to define a run script. It a script that say's linux what to do after booting completes.

The steps we want to perform are similar to the steps we did with qemu except pulling the container and building the invoker.
1. Spinning up the container
2. Pin the container to core 1
3. Reset the gem5 stats
4. Start the invoker.
5. Dump the gem5 stats
6. Exit the simulation.

The `run_function.sh` script provides already a skeleton for those steps. You only need to specify your function image at very top of the script. In our case this is `vhiveease/aes-go`.

Now start the simulator with the following command:
```bash
./gem5/build/X86/gem5.opt --outdir=results gem5-configs/run.py  --kernel workload/vmlinux --disk workload/disk-image.img --script scripts/run_function.sh
```
Gem5 will now start, boot linux and then execute the script we just modified. Note simulating HW is usually very time consuming. Booting linux using one of the detailed or even the atomic core could easily take hours. Fast forward this booting gem5 provides the nice feature to use kvm instead of any other CPU model. As soon as the booting process is completed we can then magically ;) switch to a more detailed CPU.

> Note: To inspect what is happening inside the simulator you can use the terminal tool provided by gem5. ....

While the simulation is running we can inspect what is happening by connecting the terminal tool provided by gem5. To use it open a second terminal (Ctr+b % will create a second tmux plane for you.) and connect with:
```bash
./gem5/util/term/m5term localhost 3456
```

You should see how linux boots first and then how gem5 service will start your run script.

As soon as the simulation is completed gem5 will exit. The stats file we dumped is written to the results directory `results`

The stats file contain a lot of statistic counter which where collected during the simulation. As example we will grep the cycles and instructions to see the performance of our function
```bash
grep "system.detailed_cpu1.numCycles" results/stats.txt \
&& grep "system.detailed_cpu1.exec_context.thread_0.numInsts" results/stats.txt
# A small bash script that does the math for us.
./ipc.sh results/stats.txt
```
Now you are done :) Congratulation you just simulated your first containerized function in using /the gem5 simulator. You can now start to play with your own functions or modify the configs to do even more research.

### Modify the config
In this section we will guide you exemplary through how to modify the configuration. For this we will only change the cache size and associativity of the LLC.

1. Open the `cache.py` file in the gem5-config folder. Change the LLCCache's default parameter for size and associativity into for example 8MB and 16 respectively. Save and close the file.
2. Run the same command as in the previous step to run the simulation.
```bash
./gem5/build/X86/gem5.opt --outdir=results gem5-configs/run.py  --kernel workload/vmlinux --disk workload/disk-image.img --script scripts/run_function.sh
```
3. Finally inspect the stats file. The larger cache and higher associativity should have a improved the IPC of your function. In case you are interested can also search for the number of cache misses to see how your larger LLC improved its MPKI (misses per kilo instruction).
```bash
grep "system.detailed_cpu1.numCycles" results/stats.txt && \
grep "system.detailed_cpu1.exec_context.thread_0.numInsts" results/stats.txt
# A small bash script that does the math for us.
./ipc.sh results/stats.txt
```



## Clean-up

None.
