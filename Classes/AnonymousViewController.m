#import "AnonymousViewController.h"
#import "AnonymousOverlayView.h"
#import "AnonymousAppDelegate.h"


@implementation AnonymousViewController
@synthesize previewView, overlayView, start, previewImage, ciContext, ciDetector;

#define FrameBufferWidth 360
#define FrameBufferHeight 480
#define DetectScale 2
#define LogTime 0
#define TimeToPredict 6


- (void)dealloc {
	AudioServicesDisposeSystemSoundID(alertSoundID);
	[super dealloc];
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
    self.ciContext = [CIContext contextWithOptions:nil];
	self.ciDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:ciContext options:nil];
}

- (void)finishDetection{
    self.ciDetector = nil;
    self.ciContext = nil;
}

- (void)detectFace:(UIImage *)uiImage{
    processingImage = YES;
    CIImage * ciImage = [CIImage imageWithCGImage:uiImage.CGImage];
    NSArray * features = [ciDetector featuresInImage:ciImage];
    
    // Let's assume that it's real time.
    CGRect r = ((CIFeature *)[features objectAtIndex:0]).bounds;
    
    // Replace the 1st rect. TODO: Feed the rect array directly here.
    [overlayView.rects replaceObjectAtIndex:0 withObject:[NSValue valueWithCGRect:r]];
    processingImage = NO;    
}



#pragma mark -
#pragma mark UIViewControllerDelegate

- (void)viewDidLoad {
	[super viewDidLoad];

	NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Grab" ofType:@"aif"] isDirectory:NO];
	AudioServicesCreateSystemSoundID((CFURLRef)url, &alertSoundID);

	// TODO: Check if there are images to share in the queue
	[SHK flushOfflineQueue];
	
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

//Cannot capture in simulator
#if (!TARGET_IPHONE_SIMULATOR)

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

#endif
	
}
#if (!TARGET_IPHONE_SIMULATOR)

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

#endif

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
	
	//UIImageWriteToSavedPhotosAlbum(result, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
	
	[[SHK currentHelper] setRootViewController:self];	
	
	// Popup ShareKit instead
	SHKItem *item = [SHKItem image:result title:@"Look at this picture!"];
	
	// Get the ShareKit action sheet
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
	
	// Display the action sheet
	[actionSheet showInView:self.view];
	
	// Need to resume capture when SHKShareMenu is removed from the view
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(SHKViewWasDismissed)
												 name:@"SHKSendDidFinish" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(SHKViewWasDismissed)
												 name:@"SHKSendDidCancel" object:nil];
}


- (void)SHKViewWasDismissed{
	NSLog(@"ShareKit dismissed!");
	[self resumeCapture];	
}

- (void)               image: (UIImage *) image
    didFinishSavingWithError: (NSError *) error
                 contextInfo: (void *) contextInfo{
	[self resumeCapture];
}

- (void)pauseCapture{
//Cannot capture in simulator
#if (!TARGET_IPHONE_SIMULATOR)	
	NSAssert(session, @"Capture Session not available.");
	[session stopRunning];
	takePictureButton.enabled = NO;
#endif
}

- (void)resumeCapture{
//Cannot capture in simulator
#if (!TARGET_IPHONE_SIMULATOR)	
	NSAssert(session, @"Capture Session not available.");	
	[session startRunning];
	takePictureButton.enabled = YES;
    // Hide status bar
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    // Set New overlay
    overlayView.overlay = [(AnonymousAppDelegate *)([UIApplication sharedApplication].delegate) selectedOverlay];
    
#endif
}

#pragma mark Handle Events

- (IBAction)showConfig{
	[self pauseCapture];
	AnonymousOverlaySelectionView * overlaySelectionController = [[[AnonymousOverlaySelectionView alloc]initWithNibName:@"AnonymousOverlaySelectionView" bundle:nil]autorelease];
	overlaySelectionController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;	
	[self presentModalViewController:overlaySelectionController animated:YES];
}



@end