#!/bin/bash

## Specify the function name (service name) of your function. I.e. aes-python
IMAGE_NAME=<name of your function image>
## In case the container name is different to the service name specify also the
CONTAINER_NAME=$IMAGE_NAME

## Spin up Container
echo "Start the container..."
docker run -d --name $CONTAINER_NAME -p 50051:50051 $IMAGE_NAME

echo "Pin to core 1"
docker update  $CONTAINER_NAME --cpuset-cpus 1


## Now start the invoker
pushd /root/

sleep 5

echo "
Execute m5 exit to indicate boot complete"
m5 exit

## Run the invoker
# Modify the invoker parameters depending on your need.

./client -addr localhost:50051 -n 20

## Call exit again to end the simulation
m5 exit