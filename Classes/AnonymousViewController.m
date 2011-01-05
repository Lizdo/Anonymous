#import "AnonymousViewController.h"
#import "AnonymousOverlayView.h"

@implementation AnonymousViewController
@synthesize previewView, overlayView, start, previewImage;

#define FrameBufferWidth 360
#define FrameBufferHeight 480
#define DetectScale 4
#define LogTime 0
#define TimeToPredict 6


IplImage* transposeImage(IplImage* image) {
	
	IplImage *rotated = cvCreateImage(cvSize(image->height,image->width), IPL_DEPTH_8U,image->nChannels);
	
	CvPoint2D32f center;
	
	float center_val = image->height/2.0f;
	center.x = center_val;
	center.y = center_val;
	CvMat *mapMatrix = cvCreateMat( 2, 3, CV_32FC1 );
	
	cv2DRotationMatrix(center, -90, 1.0, mapMatrix);
	cvWarpAffine(image, rotated, mapMatrix, CV_INTER_LINEAR + CV_WARP_FILL_OUTLIERS, cvScalarAll(0));
	
	cvReleaseMat(&mapMatrix);
	
	return rotated;
}

#define PredictScale 3.0f

CvRect enlargeCvRect(CvRect r){
	CGPoint midPoint = CGPointMake(r.x+r.width/2, r.y+r.height/2);
	return cvRect(midPoint.x-r.width*PredictScale/2, midPoint.y-r.height*PredictScale/2, 
					  r.width*PredictScale, r.height*PredictScale);
}

CGRect predictedRect(CGRect rect2, CGRect rect1){
	if (CGRectEqualToRect(rect2, CGRectZero) || CGRectEqualToRect(rect1, CGRectZero)) {
		return CGRectZero;
	}
	float width = rect2.size.width + (rect1.size.width - rect2.size.width) * 2;
	float height = rect2.size.height + (rect1.size.height - rect2.size.height) * 2;
	
	float x = rect2.origin.x + (rect1.origin.x - rect2.origin.x) * 2;
	float y = rect2.origin.y + (rect1.origin.y - rect2.origin.y) * 2;	
	
	return CGRectMake(x, y, width, height);
}

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
	
	gray = cvCreateImage( cvSize(FrameBufferHeight,FrameBufferWidth), 8, 1 );
	small_image = cvCreateImage( cvSize( cvRound (FrameBufferHeight/DetectScale),
												  cvRound (FrameBufferWidth/DetectScale)), 8, 1 );
	storage = cvCreateMemStorage(0);

	
}

- (void)finishDetection{
	if (cascade){
		cvReleaseHaarClassifierCascade(&cascade);		
	}
	if (storage) {
		cvReleaseMemStorage(&storage);
	}
	cvReleaseImage(&small_image);
	cvReleaseImage(&gray);
}

- (void)detectFace:(UIImage *)uiImage{
	if(uiImage) {
		processingImage = YES;
		
		cvSetErrMode(CV_ErrModeParent);
		
		test_image = [self CreateIplImageFromUIImage:uiImage];
		
		
		if (LogTime) {
			NSLog(@"IplImage: %f", -[start timeIntervalSinceNow]);
			self.start = [NSDate date];	
		}
		
		// Scaling down		
		cvCvtColor( test_image, gray, CV_BGR2GRAY );
		cvResize( gray, small_image, CV_INTER_LINEAR );
		cvEqualizeHist( small_image, small_image );

		// Turn the image -90 degree, as the format is like that from the buffer
		IplImage *temp_image = transposeImage(small_image);		

		if (LogTime) {
			NSLog(@"Rotate IplImage: %f", -[start timeIntervalSinceNow]);
			self.start = [NSDate date];		
		}

		// Detect Face
		CvSeq* faces = cvHaarDetectObjects(temp_image, cascade, storage, 1.5f, 2, CV_HAAR_FIND_BIGGEST_OBJECT|CV_HAAR_DO_ROUGH_SEARCH, cvSize(20, 20));
		
		if (LogTime) {
			NSLog(@"Detect Face: %f", -[start timeIntervalSinceNow]);
			self.start = [NSDate date];
		}

		
		// Draw results on the iamge
		for(int i = 0; i < 10; i++) {
			if (i >= faces->total) {
				if (!CGRectEqualToRect([[overlayView.rects objectAtIndex:i] CGRectValue], CGRectZero)) {
					[overlayView.rects replaceObjectAtIndex:i withObject:[NSValue valueWithCGRect:CGRectZero]];
				}
			}else{
				CvRect cvrect = *(CvRect*)cvGetSeqElem(faces, i);
				CGRect r = CGRectMake(cvrect.x * DetectScale, cvrect.y * DetectScale, cvrect.width * DetectScale, cvrect.height * DetectScale);
				[overlayView.rects replaceObjectAtIndex:i withObject:[NSValue valueWithCGRect:r]];
				//Cache the previous face for prediction
				if (i = 0) {
					previousFace2 = previousFace1;
					previousFace1 = r;
				}

			}
		}
		
		
		// If no face found, do a simple prediction
		if (faces->total == 0) {
			notFoundCount++;
			if (notFoundCount >= TimeToPredict) {
				//More than 0.5s not found, remove the face
				notFoundCount = 0;
				previousFace1 = previousFace2 = CGRectZero;
			}else {
				CGRect r = predictedRect(previousFace2, previousFace1);
				[overlayView.rects replaceObjectAtIndex:1 withObject:[NSValue valueWithCGRect:r]];
			}
		}
		

		[overlayView performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
		//[overlayView setNeedsDisplay];
		
		//Need to release IplImage from CreateIplImageFromUIImage()
		cvReleaseImage(&temp_image);
		cvReleaseImage(&test_image);
		
		if (LogTime) {
			NSLog(@"Draw Result: %f", -[start timeIntervalSinceNow]);
			start = nil;
		}
		
		processingImage = NO;		
	}
}



#pragma mark -
#pragma mark UIViewControllerDelegate

- (void)viewDidLoad {
	[super viewDidLoad];

	NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Grab" ofType:@"aif"] isDirectory:NO];
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
	if (LogTime) {
		self.start = [NSDate date];
	}
	
	UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
	//imageView.image = image;

	
	//[self performSelectorOnMainThread:@selector(detectFace:) withObject:image waitUntilDone:NO];
	
	[self detectFace:image];
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
	
	if (LogTime) {
		NSLog(@"Buffer to CGImage: %f", -[start timeIntervalSinceNow]);
		self.start = [NSDate date];
	}
	
    // Create an image object from the Quartz image
	// Rotate for image taken from back camera
	self.previewImage = [UIImage imageWithCGImage:quartzImage scale:1 orientation:UIImageOrientationRight];
	//self.previewImage = [UIImage imageWithCGImage:[self CGImageRotatedByAngle:quartzImage angle:-90]];
	UIImage * image = [UIImage imageWithCGImage:quartzImage];
	
	if (LogTime) {
		NSLog(@"Rotate CGImage: %f", -[start timeIntervalSinceNow]);
		self.start = [NSDate date];
	}
	
    // Release the Quartz image
    CGImageRelease(quartzImage);
	
    return (image);
}

//Freeze the image and write to a imageView
- (void)saveImage{
	[self pauseCapture];
	//Flash to white
	AudioServicesPlaySystemSound(alertSoundID);

	UIView *white = [[UIView alloc] initWithFrame:self.view.bounds];
	white.backgroundColor = [UIColor whiteColor];
	white.alpha = 0;
	[self.view addSubview:white];
	[UIView animateWithDuration:0.2
					 animations:^{white.alpha = 1.0;}
					 completion:^(BOOL finished){
						 [white performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.1];
						 //Save after Anim/Sound to avoid clutter...
						 [self performSelector:@selector(actualSave) withObject:nil afterDelay:0.2];				 
					 }]; 
}

- (void)actualSave{
	// Do the actual save here 
	CGSize size = previewView.frame.size;
	UIGraphicsBeginImageContext(size);
	
	[previewImage drawAtPoint:CGPointZero];
	
	UIImage* overlay = [overlayView renderToImage];
	[overlay drawAtPoint:CGPointZero];	
	
	UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	UIImageWriteToSavedPhotosAlbum(result, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)               image: (UIImage *) image
    didFinishSavingWithError: (NSError *) error
                 contextInfo: (void *) contextInfo{
	[self resumeCapture];
}

- (void)pauseCapture{
	NSAssert(session, @"Capture Session not available.");
	[session stopRunning];
	takePictureButton.enabled = NO;
}

- (void)resumeCapture{
	NSAssert(session, @"Capture Session not available.");	
	[session startRunning];
	takePictureButton.enabled = YES;
}

#pragma mark Handle Events

- (IBAction)showConfig{
	[self pauseCapture];
	AnonymousOverlaySelectionView * overlaySelectionController = [[[AnonymousOverlaySelectionView alloc]initWithNibName:@"AnonymousOverlaySelectionView" bundle:nil]autorelease];
	overlaySelectionController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;	
	[self presentModalViewController:overlaySelectionController animated:YES];
}



@end