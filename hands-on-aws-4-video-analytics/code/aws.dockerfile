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

FROM amazon/aws-lambda-python:latest as recogBuilder

COPY ./benchmarks/video-analytics/object_recognition/aws/requirements.txt ./
RUN pip3 install torch==1.9.0+cpu torchvision==0.10.0+cpu torchaudio==0.9.0 -f https://download.pytorch.org/whl/torch_stable.html && \
    pip3 install -r requirements.txt
COPY ./benchmarks/video-analytics/object_recognition/aws/handler.py ./
COPY ./benchmarks/video-analytics/object_recognition/aws/storage_util.py ./
COPY ./benchmarks/video-analytics/object_recognition/aws/imagenet_labels.txt ./
ENV PATH=/root/.local/bin:$PATH
CMD [ "handler.lambda_handler" ]


FROM vhiveease/python-slim:latest as decodeBuilder
WORKDIR /py
COPY ./benchmarks/video-analytics/decoder/aws/requirements.txt ./
RUN apt update && \
    apt-get install ffmpeg libsm6 libxext6 -y && \
    pip3 install --no-cache-dir --target ./ ffmpeg-python && \
    pip3 install --no-cache-dir --target ./ opencv-python && \
    pip3 install --no-cache-dir --target ./ -r requirements.txt
RUN pip3 install --no-cache-dir --target ./ awslambdaric

#COPY ./utils/tracing/python/tracing.py ./
COPY ./benchmarks/video-analytics/decoder/aws/handler.py ./
COPY ./benchmarks/video-analytics/decoder/aws/storage_util.py ./
ENV PATH=/root/.local/bin:$PATH
ENTRYPOINT [ "python3", "-m", "awslambdaric" ]
CMD [ "handler.lambda_handler" ]


FROM vhiveease/golang:latest as streamingBuilder
WORKDIR /app/app/
RUN apk add --no-cache make
RUN apk add -U --no-cache ca-certificates
COPY ./benchmarks/video-analytics/video_streaming/aws/handler.go ./video_streaming/
COPY ./benchmarks/video-analytics/video_streaming/aws/streaming-video.mp4 ./video_streaming/
COPY ./benchmarks/video-analytics/video_streaming/aws/go.mod ./
COPY ./benchmarks/video-analytics/video_streaming/aws/go.sum ./
RUN go mod download && \
   CGO_ENABLED=0 GOOS=linux go build -v -o ./video_streaming/streaming-bin ./video_streaming

FROM scratch as streaming
WORKDIR /app
COPY --from=streamingBuilder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=streamingBuilder /app/app/video_streaming/streaming-bin /app/gen/exe
COPY --from=streamingBuilder /app/app/video_streaming/streaming-video.mp4 /app/streaming-video.mp4

ENTRYPOINT [ "/app/gen/exe" ]