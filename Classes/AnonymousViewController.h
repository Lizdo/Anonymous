#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreImage/CoreImage.h>

#import "UIView+SaveToImage.h"
#import "AnonymousOverlaySelectionView.h"


// Import ShareKit
#import "SHK.h"

@class AnonymousOverlayView;
@class AVCaptureSession;


@interface AnonymousViewController : UIViewController{
#if (!TARGET_IPHONE_SIMULATOR)

	AVCaptureSession *session;
#endif
	
	IBOutlet UIView *previewView;
	IBOutlet AnonymousOverlayView *overlayView;	
	IBOutlet UIButton *takePictureButton;

	BOOL processingImage;
	
	SystemSoundID alertSoundID;
	
	UIImage *previewImage;
	
	NSDate *start;
	
	int notFoundCount;
    
    CIDetector * ciDetector;
    CIContext * ciContext;
}

@property (nonatomic, retain) UIView *previewView;
@property (nonatomic, retain) UIImage *previewImage;
@property (nonatomic, retain) AnonymousOverlayView *overlayView;
@property (nonatomic, retain) NSDate *start;
@property (nonatomic, retain) CIDetector * ciDetector;
@property (nonatomic, retain) CIContext * ciContext;


- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer;
- (IBAction)saveImage;

- (IBAction)showConfig;

- (void)pauseCapture;
- (void)resumeCapture;

@end