import logging as log
from storage_util import Storage
import io
import os
import json

from torchvision import transforms
from PIL import Image
import torch
import torchvision.models as models
# from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all
patch_all()

INLINE = "INLINE"
S3 = "S3"
ELASTICACHE = "ELASTICACHE"

log.basicConfig(level=log.INFO)

# Load model
import urllib.request
model = models.SqueezeNet("1_1")
urllib.request.urlretrieve("https://download.pytorch.org/models/squeezenet1_1-b8a52dc0.pth", "/tmp/squeezenet1_1.pth")
model.load_state_dict(torch.load('/tmp/squeezenet1_1.pth'))
# model.load_state_dict(torch.load('squeezenet1_1.pth'))

labels_fd = open('imagenet_labels.txt', 'r')
labels = []
for i in labels_fd:
    labels.append(i)
labels_fd.close()


def infer(batch_t):
    # with tracing.Span("infer"):
    # Set up model to do evaluation
    model.eval()

    # Run inference
    with torch.no_grad():
        out = model(batch_t)

    # Print top 5 for logging
    _, indices = torch.sort(out, descending=True)
    percentages = torch.nn.functional.softmax(out, dim=1)[0] * 100
    for idx in indices[0][:5]:
        log.info('\tLabel: %s, percentage: %.2f' % (labels[idx], percentages[idx].item()))

    # make comma-seperated output of top 100 label
    out = ""
    for idx in indices[0][:100]:
        out = out + labels[idx] + ","
    return out


def preprocessImage(imageBytes):
    # with tracing.Span("preprocess"):
    img = Image.open(io.BytesIO(imageBytes))

    transform = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225]
        )
    ])

    img_t = transform(img)
    return torch.unsqueeze(img_t, 0)


def recognise(request, context):
    log.info("received a call")
    storage = Storage("S3", os.environ.get('BUCKET_NAME', 'aws-video-analytics'))
    # get the frame from s3 or inline
    frame = None
    if request['transferType'] == S3 or request['transferType'] == ELASTICACHE:
        log.info("retrieving target frame '%s' from s3/elasticache" % request['s3key'])
        # with tracing.Span("Frame fetch"):
        # urllib.request.urlretrieve("https://file-examples-com.github.io/uploads/2017/10/file_example_JPG_100kB.jpg", "/tmp/bla.jpg")
        # file = open("/tmp/bla.jpg", "rb")
        # frame = file.read()
        frame = storage.get(request['s3key'], doPickle=False)
    elif request['transferType'] == INLINE:
        frame = request.frame

    log.info("performing image recognition on frame")
    classification = infer(preprocessImage(frame))
    log.info("object recogintion successful")
    return classification


def lambda_handler(event, context):
    # TODO implement
    return {
        'statusCode': 200,
        'body': json.dumps(recognise(event, context))
    }