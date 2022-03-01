# MIT License
#
# Copyright (c) 2021 Michal Baczun and EASE lab
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

ROOT = ../../

all: all-image 

all-image: decoder-image recog-image streaming-image

all-image-push: decoder-image-push recog-image-push streaming-image-push

decoder-image: Dockerfile decoder/aws/handler.py decoder/aws/storage_util.py decoder/aws/requirements.txt
	DOCKER_BUILDKIT=1 docker build \
	-t 356764711652.dkr.ecr.us-west-1.amazonaws.com/video-analytics-decoder-aws \
	--target decodeBuilder \
	-f aws.dockerfile \
	$(ROOT)

recog-image: Dockerfile object_recognition/aws/handler.py object_recognition/aws/imagenet_labels.txt object_recognition/aws/requirements.txt object_recognition/aws/squeezenet1_1.pth
	DOCKER_BUILDKIT=1 docker build \
	-t 356764711652.dkr.ecr.us-west-1.amazonaws.com/video-analytics-recog-aws \
	--target recogBuilder \
	-f aws.dockerfile \
	$(ROOT)

streaming-image: video_streaming/aws/handler.go video_streaming/aws/streaming-video.mp4
	DOCKER_BUILDKIT=1 docker build \
	-t 356764711652.dkr.ecr.us-west-1.amazonaws.com/video-analytics-streaming-aws \
	--target streaming \
	-f aws.dockerfile \
	$(ROOT)

decoder-image-push: decoder-image
	docker push 356764711652.dkr.ecr.us-west-1.amazonaws.com/video-analytics-decoder-aws

recog-image-push: recog-image
	docker push 356764711652.dkr.ecr.us-west-1.amazonaws.com/video-analytics-recog-aws

streaming-image-push: streaming-image
	docker push 356764711652.dkr.ecr.us-west-1.amazonaws.com/video-analytics-streaming-aws
