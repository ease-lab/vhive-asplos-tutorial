# Setup

* [Install `gcloud`](https://cloud.google.com/sdk/docs/install#installation_instructions)

* Bulk creating VM instances with dependencies for the tutorial.

```bash
# First, create reservation if necessary.
gcloud compute reservations create reservation-test \
    --vm-count=N \
    --machine-type=n1-standard-4 \
    --min-cpu-platform="Intel Haswell" \
    --local-ssd=size=375,interface=scsi \
    --zone=us-west1-c

# Use the exact specifications listed in the command to create VMs.
# Replace `N` with the number of instances needed. 
gcloud compute instances bulk create \
    --name-pattern="vhive-vm-###"\
    --count=N \
    --enable-nested-virtualization \
    --machine-type=n1-standard-4 \
    --boot-disk-size=100GB \
    --min-cpu-platform="Intel Haswell" \
    # Change the following if you update the current image with your dependencies.
    --image=image=projects/vhive-tutorial/global/images/vhive-tracing \ 
    --zone=us-west1-c \
    --reservation-affinity=any
```

* Save the instance to a custom image.

```bash
gcloud compute images create IMAGE_NAME \
    --source-disk=SOURCE_DISK \
    --source-disk-zone=ZONE \
    [--family=IMAGE_FAMILY] \
    [--storage-location=LOCATION] \
    [--force]
```

## Clean-up

To remove all the instances, go to GCP console, select all instances, and click the delete button :)