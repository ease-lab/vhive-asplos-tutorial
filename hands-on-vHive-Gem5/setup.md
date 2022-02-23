> [Gem5 Tutorial](README.md) ▸ **Setup**
# Setup Gem5 for Full-System simulation

In oder to run full system simulations gem5 prerequires three essential components.
## Essential:
1. Compiled gem5 sources
2. Compiled linux kernel configured for gem5
3. Disk image with root file system installed

By having gem5 compiled, a kernel binary and a disk image you are ready to boot linux with gem5. However, for evaluation and automation of your simulation workflow we recommend to also add the m5 binaries and create a m5 init service.

## Additional:
1. Add `m5` binaries
2. Create m5init service


## Build gem5 resources
To run simulation models with gem5 first all resources need to be build. Follow [this](https://www.gem5.org/documentation/learning_gem5/part1/building/) build steps. For confinience you can also use the `build_gem5.sh` script.
```bash
./scripts/build_gem5.sh
```
This script will install all prerequirements, pull the gem5 repo and build all components of gem5. Depending on our machine and the number of cores you use to build this can take up to 15 minutes.

## Build linux kernel
Gem5 requires a binary to be executed after startup in our case this is the linux kernel. To build a custom kernel for gem5 we need to basically follow the steps [here](https://gem5.googlesource.com/public/gem5-resources/+/refs/heads/stable/src/linux-kernel/). From this site you can also get preconfigured kernel configs where all required moduls for gem5 are enabled.

However, since we want to run container workloads additional modules are required. The `config/` folder contains a config file for kernel version 5.4.84 that can run container workloads with gem5. We will use it to build our kernel with the following commands.
```
# Build kernel for gem5 supporting contianerized workloads
KVERSION=5.4.84
ARCH=amd64

sudo apt install libelf-dev libncurses-dev -y

# Get sources
git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git ../linux
pushd ../linux
git checkout v${KVERSION}

# apply the configuration
cp ../config/linux-${KVERSION}.config .config

## build kernel
make -j $(nproc)
popd
```

Alternativelly use the `build_kernel.sh` script which will do all those steps for you and place the final executable into the `workload/` folder.
```
./scripts/build_kernel.sh
```

### Customize linux kernel
If you need to enable additional modules you may want to customize the kernel config. For this the easiest way is to start from one of the existing preconfigurations. For this overwrite the good `.config` file in the linux repo with the config you want and start the configuration process as usual with `make oldconfig`.

### Check kernel config for container workloads
To find out if your kernel is ready to run container workloads the developers from the moby project provided a very convenient [scripts](https://github.com/moby/moby/raw/master/contrib/check-config.sh).
This [blog post](https://blog.hypriot.com/post/verify-kernel-container-compatibility/) explains very nicely how to use this script to verify your kernel config for compatibility.

> Note: Gem5 cannot load modules at runtime therefore all modules need to be build into the binary.

## Create basic ubuntu disk image
The last essential component is a disk image with a root file system installed on it. There are several ways to create disk images all described [here](https://www.gem5.org/documentation/general_docs/fullsystem/disks).

We recommend to follow the instructions in option 3) and use `qemu` to create your first disk images. Using `qemu` enables you to configure your disk image with your serverless function and test all your setup before switching to the simulator.

To make the ubuntu install process more convenient we created a [script](scripts/build_disk_image) and config files that which will handle the very first steps for you:

1. Create disk image
2. Get installation medium for Ubuntu server 20.04
3. Start the ubuntu installation
4. Create a `root` user for with password `root`

In addition this script will also perform the optional steps to add the optional tools for gem5 as well as



[add the gem5 binary](#add-gem5-binary) and
5. Finally it will



## Optional Setups specifically for Gem5
The following two steps are optional but recommend to do for enhancing your simulation workflow.

### Add gem5 binary
The `m5` binary is a useful tool to execute magic instructions from the running system. After installation you can use this tool in scripts or even in the command line to for example take a snapshot or exit the simulation. Type `m5 -h` for available subcommands. More information about the `m5` binary you will find [here](https://www.gem5.org/documentation/general_docs/m5ops/).

Btw. by using the `build_gem5.sh` script we already build the m5 utility tool for you.

### Create an gem5 init service.
Using the `m5` tool


## Useful resources
[Create disk image for gem5](http://www.lowepower.com/jason/setting-up-gem5-full-system.html)
