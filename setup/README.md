
# Setup

## Create instances

* [Install `gcloud`](https://cloud.google.com/sdk/docs/install#installation_instructions)

* Bulk creating VM instances with dependencies for the tutorial.

```bash
# First, make reservation if necessary.
gcloud compute reservations create reservation-test \
    --vm-count=N \
    --machine-type=n1-standard-4 \
    --min-cpu-platform="Intel Haswell" \
    --local-ssd=size=375,interface=scsi \
    --zone=us-west1-c

# Use the exact specifications listed in the command to create VMs.
# Replace `N` with the number of instances needed. 
# (It takes about a minute to create 50 instances)
gcloud compute instances bulk create \
    --name-pattern="vhive-vm-###"\
    --count=1 \
    --enable-nested-virtualization \
    --machine-type=n1-standard-4 \
    --boot-disk-size=100GB \
    --min-cpu-platform="Intel Haswell" \
    --image-family=base-v2 \
    --image-project=vhive-tutorial-asplos2022 \
    --zone=us-west1-c \
    --reservation-affinity=any
```

* Retrieve created instances: `gcloud compute instances list`.

## Create an image

* First, you must make a snapshot (please don't halt/shutdown the VM for baking the image).

```bash
gcloud compute disks snapshot <name> \
    --project=vhive-tutorial-asplos2022 \  --snapshot-names=vhive-tutorial-snapshot \
    --zone=us-west1-c \
    --storage-location=us
```

* Create an image from the snapshot.

```bash
gcloud compute images create vhive-vm-image \
    --project=vhive-tutorial-asplos2022 \
    --family=base-v2 \
    --source-snapshot=vhive-tutorial-snapshot \
    --storage-location=us
```


## Clean-up

To remove all the instances, go to GCP console, select all instances, and click the delete button :)