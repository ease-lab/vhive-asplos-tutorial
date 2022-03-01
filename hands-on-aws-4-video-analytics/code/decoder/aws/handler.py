import json
from storage_util import Storage
import tempfile
import cv2
import logging as log
import boto3
import os
from aws_xray_sdk.core import patch_all
patch_all()

S3 = "S3"
INLINE = "INLINE"
ELASTICACHE = "ELASTICACHE"


def decodeFrames(request, fileBytes):
    temp = tempfile.NamedTemporaryFile(suffix=".mp4")
    temp.write(fileBytes)
    temp.seek(0)

    all_frames = []
    # with tracing.Span("Decode frames"):
    vidcap = cv2.VideoCapture(temp.name)
    frame_skip = int(os.environ.get('DECODER_FRAMES', '1'))
    for i in range(60):
        success, image = vidcap.read()
        if i % frame_skip == 0:
            all_frames.append(cv2.imencode('.jpg', image)[1].tobytes())

    return all_frames


def processFrames(request, videoBytes):
    frames = decodeFrames(request, videoBytes)
    # with tracing.Span("Recognise all frames"):
    all_result_futures = []
    # send all requests
    decoderFrames = 1
    frames = frames[0:decoderFrames]
    # if os.getenv('CONCURRENT_RECOG', "false").lower() == "false":
    # concat all results
    frameCount = 1
    for frame in frames:
        request['frameCount'] = frameCount
        all_result_futures.append(recognise(request, frame))
        frameCount = frameCount + 1
    # else:
    #     ex = futures.ThreadPoolExecutor(max_workers=decoderFrames)
    #     all_result_futures = ex.map(self.Recognise, frames)
    log.info("returning result of frame classification")
    results = ""
    for result in all_result_futures:
        results = results + result + ","

    return results


def recognise(request, frame):
    # channel = grpc.insecure_channel(args.addr)
    # stub = videoservice_pb2_grpc.ObjectRecognitionStub(channel)
    # result = b''
    storage = Storage("S3", os.environ.get('BUCKET_NAME', 'aws-video-analytics'))
    if request["transferType"] == S3 or request["transferType"] == ELASTICACHE:
        name = "frames/decoder-frame-" + str(request['frameCount']) + ".jpg"
        # with tracing.Span("Upload frame"):
        storage.put(name, frame, doPickle = False)
        log.info("calling recog with s3/elasticache` key")
        # response = stub.Recognise(videoservice_pb2.RecogniseRequest(s3key=name))
        lambda_client = boto3.client("lambda")
        response = lambda_client.invoke(
            FunctionName=os.environ.get('RECOG_FUNCTION', 'video-analytics-recog-aws'),
            InvocationType='RequestResponse',
            LogType='None',
            Payload=json.dumps({"s3key":name, "transferType":request["transferType"]}),
        )
        payloadBytes = response['Payload'].read()
        payloadJson = json.loads(payloadBytes)

        return payloadJson['body']
        # result = response.classification
    elif request["transferType"] == INLINE:
        log.info("calling recog with inline data")
        # response = stub.Recognise(videoservice_pb2.RecogniseRequest(frame=frame))
        # result = response.classification

    return response


def decode(request, context):
    log.info("Decoder recieved a request")
    storage = Storage("S3", os.environ.get('BUCKET_NAME', 'aws-video-analytics'))
    videoBytes = b''
    if request["transferType"] == S3 or request["transferType"] == ELASTICACHE:
        log.info("Using s3, getting bucket")
        # with tracing.Span("Video fetch"):
        videoBytes = storage.get(request['s3key'], doPickle=False)
        log.info("decoding frames of the s3/elasticache object")
    elif request["transferType"] == INLINE:
        log.info("Inline video decode. Decoding frames.")
        videoBytes = request.video
    results = processFrames(request, videoBytes)
    return results


def lambda_handler(event, context):
    # TODO implement
    return {
        'statusCode': 200,
        'body': json.dumps(decode(event, context))
    }