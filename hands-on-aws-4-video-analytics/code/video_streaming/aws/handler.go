package main

import (
	"context"
	"encoding/json"
	"fmt"
	runtime "github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/lambda"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"github.com/aws/aws-xray-sdk-go/xray"
	log "github.com/sirupsen/logrus"
	"io/ioutil"
	"os"
	"strconv"
)

//var client = lambda.New(session.New())
//
//func callLambda() (string, error) {
//	input := &lambda.GetAccountSettingsInput{}
//	req, resp := client.GetAccountSettingsRequest(input)
//	err := req.Send()
//	output, _ := json.Marshal(resp.AccountUsage)
//	return string(output), err
//}

var (
	AKID             string
	ELASTICACHE_URL  string
	AWS_S3_BUCKET    = "aws-video-analytics"
	DECODER_FUNCTION = "video-analytics-decoder-aws"
)

const (
	videoFile     = "streaming-video.mp4"
	TOKEN         = ""
	INLINE        = "INLINE"
	S3            = "S3"
	ELASTICACHE   = "ELASTICACHE"
	AWS_S3_REGION = "us-west-1"
)

func uploadToS3(ctx context.Context) {
	ctx, root := xray.BeginSegment(context.TODO(), "S3 upload")
	defer root.Close(nil)
	file, err := os.Open(videoFile)
	if err != nil {
		log.Fatalf("[Video Streaming] Failed to open file: %s", err)
	}

	s3session, err := session.NewSession(&aws.Config{
		Region: aws.String(AWS_S3_REGION),
	})
	if err != nil {
		log.Fatalf("Failed establish s3 session: %s", err)
	}

	if value, ok := os.LookupEnv("BUCKET_NAME"); ok {
		AWS_S3_BUCKET = value
	}

	log.Infof("uploading to S3 bucket %s", AWS_S3_BUCKET)

	uploader := s3manager.NewUploader(s3session)
	_, err = uploader.UploadWithContext(ctx, &s3manager.UploadInput{
		Bucket: aws.String(AWS_S3_BUCKET),
		Key:    aws.String("streaming-video.mp4"),
		Body:   file,
	})
	log.Infof("S3 upload complete")
	if err != nil {
		log.Fatalf("Failed to upload bytes to s3: %s", err)
	}
	//return key

	log.Infof("[Video Streaming] Uploaded video to s3")
}

func uploadToRedis(ctx context.Context) {

	file, err := ioutil.ReadFile(videoFile)
	if err != nil {
		log.Fatalf("[Video Streaming] Failed to open file: %s", err)
	}

	log.Infof("[Video Streaming] Uploading %d bytes to ElastiCache", len(file))
	key := "streaming-video.mp4"

	//storage.Put(key, file)
	log.Infof("[Video Streaming] Uploaded %q to elasticache %q", key, ELASTICACHE_URL)
}

type Event struct {
	Name         string `json:"name"`
	TransferType string `json:"TransferType"`
}

type InvokeRequest struct {
	TransferType  string `json:"transferType"`
	DecoderFrames string `json:"decoderFrames"`
	S3Key         string `json:"s3key"`
}

type Response struct {
	StatusCode int    `json:"statusCode"`
	Body       string `json:"body"`
}

func invokeLambda(ctx context.Context, key string) string {
	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))

	client := lambda.New(sess, &aws.Config{Region: aws.String("us-west-1")})
	xray.AWS(client.Client)

	request := InvokeRequest{"S3", "1", key}

	payload, err := json.Marshal(request)
	if err != nil {
		fmt.Println("Error marshalling MyGetItemsFunction request")
		os.Exit(0)
	}

	if value, ok := os.LookupEnv("DECODER_FUNCTION"); ok {
		DECODER_FUNCTION = value
	}

	result, err := client.InvokeWithContext(ctx, &lambda.InvokeInput{FunctionName: aws.String(DECODER_FUNCTION), Payload: payload})
	if err != nil {
		fmt.Println("Error calling MyGetItemsFunction")
		os.Exit(0)
	}

	var resp Response

	err = json.Unmarshal(result.Payload, &resp)
	if err != nil {
		fmt.Println("Error unmarshalling MyGetItemsFunction response")
		os.Exit(0)
	}

	// If the status code is NOT 200, the call failed
	if resp.StatusCode != 200 {
		fmt.Println("Error getting items, StatusCode: " + strconv.Itoa(resp.StatusCode))
		os.Exit(0)
	}

	return resp.Body

}

func handleRequest(ctx context.Context, event Event) (string, error) {
	// event
	log.Printf("EVENT: %s", event.Name)

	var response string
	if event.TransferType == S3 || event.TransferType == INLINE || event.TransferType == ELASTICACHE {
		if event.TransferType == S3 {
			// upload video to s3
			xray.Capture(ctx, "S3 upload", func(ctx1 context.Context) error {
				uploadToS3(ctx1)
				xray.AddMetadata(ctx1, "S3 upload", nil)
				return nil
			})
			// issue request
			response = invokeLambda(ctx, "streaming-video.mp4")
		} else if event.TransferType == ELASTICACHE {
			uploadToRedis(ctx)
		} else {
			//reply, err = client.Decode(ctx, &pb_video.DecodeRequest{Video: videoFragment})
		}
		//response = reply.Classification
	} else {
		log.Fatalf("Invalid TRANSFER_TYPE value")
	}

	log.Infof("[Video Streaming] Received Decoder reply")
	//return response, err

	return response, nil
}

func main() {
	xray.Configure(xray.Config{
		DaemonAddr:     "127.0.0.1:2000", // default
		ServiceVersion: "1.2.3",
	})
	runtime.Start(handleRequest)
}
