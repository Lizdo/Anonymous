#import "AnonymousViewController.h"
#import "AnonymousOverlayView.h"

@implementation AnonymousViewController
@synthesize previewView, overlayView, imageView;

#define FrameBufferWidth 360
#define FrameBufferHeight 480
#define DetectScale 4


- (void)dealloc {
	AudioServicesDisposeSystemSoundID(alertSoundID);
	[super dealloc];
}

#pragma mark -
#pragma mark OpenCV Support Methods

// NOTE you SHOULD cvReleaseImage() for the return value when end of the code.
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
	CGImageRef imageRef = image.CGImage;

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	IplImage *iplimage = cvCreateImage(cvSize(image.size.width, image.size.height), IPL_DEPTH_8U, 4);
	CGContextRef contextRef = CGBitmapContextCreate(iplimage->imageData, iplimage->width, iplimage->height,
													iplimage->depth, iplimage->widthStep,
													colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
	CGContextDrawImage(contextRef, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);
	CGContextRelease(contextRef);
	CGColorSpaceRelease(colorSpace);

	IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
	cvCvtColor(iplimage, ret, CV_RGBA2BGR);
	cvReleaseImage(&iplimage);

	return ret;
}

// NOTE You should convert color mode as RGB before passing to this function
- (UIImage *)UIImageFromIplImage:(IplImage *)image {
	NSLog(@"IplImage (%d, %d) %d bits by %d channels, %d bytes/row %s", image->width, image->height, image->depth, image->nChannels, image->widthStep, image->channelSeq);

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
	CGImageRef imageRef = CGImageCreate(image->width, image->height,
										image->depth, image->depth * image->nChannels, image->widthStep,
										colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
										provider, NULL, false, kCGRenderingIntentDefault);
	UIImage *ret = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	return ret;
}

- (CGImageRef)CGImageRotatedByAngle:(CGImageRef)imgRef angle:(CGFloat)angle {
	
	float angleInRadians = angle * (M_PI / 180);
	float width = CGImageGetWidth(imgRef);
	float height = CGImageGetHeight(imgRef);
	
	CGRect imgRect = CGRectMake(0, 0, width, height);
	CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
	CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef bmContext = CGBitmapContextCreate(NULL,
												   rotatedRect.size.width,
												   rotatedRect.size.height,
												   8,
												   0,
												   colorSpace,
												   kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease(colorSpace);
	CGContextTranslateCTM(bmContext,
						  +(rotatedRect.size.width/2),
						  +(rotatedRect.size.height/2));
	CGContextRotateCTM(bmContext, angleInRadians);
	CGContextTranslateCTM(bmContext,
						  -(rotatedRect.size.width/2),
						  -(rotatedRect.size.height/2));
	CGContextDrawImage(bmContext, CGRectMake(0, 0,
											 rotatedRect.size.width,
											 rotatedRect.size.height),
					   imgRef);
	
	CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
	CFRelease(bmContext);
	[(id)rotatedImage autorelease];
	
	return rotatedImage;
}

#pragma mark -
#pragma mark Utilities for intarnal use

- (void)prepareToDetectFace{
	// Load XML
	NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"];
	cascade = (CvHaarClassifierCascade*)cvLoad([path cStringUsingEncoding:NSASCIIStringEncoding], NULL, NULL, NULL);
	
	test_image = cvCreateImage( cvSize(FrameBufferWidth,FrameBufferHeight), 8, 1 );
	gray = cvCreateImage( cvSize(FrameBufferWidth,FrameBufferHeight), 8, 1 );
	small_image = cvCreateImage( cvSize( cvRound (FrameBufferWidth/DetectScale),
												  cvRound (FrameBufferHeight/DetectScale)), 8, 1 );
	storage = cvCreateMemStorage(0);

	
}

- (void)finishDetection{
	if (cascade){
		cvReleaseHaarClassifierCascade(&cascade);		
	}
	if (storage) {
		cvReleaseMemStorage(&storage);
	}
	cvReleaseImage(&test_image);
	cvReleaseImage(&small_image);
	cvReleaseImage(&gray);
}

- (void)detectFace:(UIImage *)uiImage{
	if(uiImage) {
		processingImage = YES;
		
		imageView.image = uiImage;
		
		cvSetErrMode(CV_ErrModeParent);
		
		test_image = [self CreateIplImageFromUIImage:uiImage];
		
		// Scaling down		
		cvCvtColor( test_image, gray, CV_BGR2GRAY );
		cvResize( gray, small_image, CV_INTER_LINEAR );
		cvEqualizeHist( small_image, small_image );
		
		//Benchmark Start
		start = [NSDate date];
		
		// Detect faces and draw rectangle on them
		CvSeq* faces = cvHaarDetectObjects(small_image, cascade, storage, 1.5f, 2, CV_HAAR_DO_CANNY_PRUNING, cvSize(20, 20));
		
		NSTimeInterval timeInterval = [start timeIntervalSinceNow];
		NSLog(@"Time Take: %f", timeInterval);
		//Benchmark End

		// Create canvas to show the results
		CGImageRef imageRef = imageView.image.CGImage;
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGContextRef contextRef = CGBitmapContextCreate(NULL, FrameBufferWidth, FrameBufferHeight,
														8, FrameBufferWidth * 4,
														colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
		CGContextDrawImage(contextRef, CGRectMake(0, 0, FrameBufferWidth, FrameBufferHeight), imageRef);
		
		CGContextSetLineWidth(contextRef, 4);
		CGContextSetRGBStrokeColor(contextRef, 0.0, 0.0, 1.0, 0.5);
				
		// Draw results on the iamge
		for(int i = 0; i < faces->total; i++) {
			NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
			
			// Calc the rect of faces
			CvRect cvrect = *(CvRect*)cvGetSeqElem(faces, i);
			CGRect face_rect = CGContextConvertRectToDeviceSpace(contextRef, CGRectMake(cvrect.x * DetectScale, cvrect.y * DetectScale, cvrect.width * DetectScale, cvrect.height * DetectScale));
			
			NSLog(@"Face Detected@%f,%f,%f,%f", face_rect.origin.x, face_rect.origin.y
				  ,face_rect.size.width,face_rect.size.height);
			

			CGContextStrokeRect(contextRef, face_rect);
			[pool release];
		}
		
		CGImageRef c = CGBitmapContextCreateImage(contextRef);
		imageView.image = [UIImage imageWithCGImage:c];
		
		CGImageRelease(c);
		CGContextRelease(contextRef);
		CGColorSpaceRelease(colorSpace);
		
		//Need to release IplImage from CreateIplImageFromUIImage()
		cvReleaseImage(&test_image);

		
		processingImage = NO;		
	}
}



#pragma mark -
#pragma mark UIViewControllerDelegate

- (void)viewDidLoad {
	[super viewDidLoad];
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];

	NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Tink" ofType:@"aiff"] isDirectory:NO];
	AudioServicesCreateSystemSoundID((CFURLRef)url, &alertSoundID);

	[self prepareToDetectFace];

	[self performSelector:@selector(startCapture) withObject:nil afterDelay:0.1];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if(interfaceOrientation == UIInterfaceOrientationPortrait){
		return YES;
	}else {
		return NO;
	}
}


- (void)startCapture{
	
	// start capturing frames
	// Create the AVCapture Session
	session = [[AVCaptureSession alloc] init];
	
	// create a preview layer to show the output from the camera
	AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
	previewLayer.frame = previewView.frame;
	[previewView.layer addSublayer:previewLayer];
	
	// Get the default camera device
	AVCaptureDevice* camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	
	// Create a AVCaptureInput with the camera device
	NSError *error=nil;
	AVCaptureInput* cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
	if (cameraInput == nil) {
		NSLog(@"Error to create camera capture:%@",error);
	}
	
	// Set the output
	AVCaptureVideoDataOutput* videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	
	// create a queue to run the capture on
	dispatch_queue_t captureQueue=dispatch_queue_create("catpureQueue", NULL);
	
	// setup our delegate
	[videoOutput setSampleBufferDelegate:self queue:captureQueue];
	dispatch_release(captureQueue);
	
	// configure the pixel format
	videoOutput.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
								 nil];
	videoOutput.minFrameDuration = CMTimeMake(1, 15);
	
	
	// and the size of the frames we want
	[session setSessionPreset:AVCaptureSessionPresetMedium];
	
	// Add the input and output
	[session addInput:cameraInput];
	[session addOutput:videoOutput];
	
	// Start the session
	[session startRunning];	
	
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
	   fromConnection:(AVCaptureConnection *)connection {
	if (processingImage) {
		return;
	}
	NSLog(@"Frame Captured");
	UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
	//imageView.image = image;

	
	[self performSelectorOnMainThread:@selector(detectFace:) withObject:image waitUntilDone:NO];

	//[self detectFace:image];
}

// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer 
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0); 
	
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer); 
	
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer); 
    size_t height = CVPixelBufferGetHeight(imageBuffer); 
		
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
	
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, 
												 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst); 
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context); 
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
	
    // Free up the context and color space
    CGContextRelease(context); 
    CGColorSpaceRelease(colorSpace);
	
    // Create an image object from the Quartz image
	// Rotate for image taken from back camera
	//UIImage *image = [UIImage imageWithCGImage:quartzImage scale:(CGFloat)1.0 orientation:UIImageOrientationRight];	
	UIImage *image = [UIImage imageWithCGImage:[self CGImageRotatedByAngle:quartzImage angle:-90]];	
    // Release the Quartz image
    CGImageRelease(quartzImage);
	
    return (image);
}



@end