#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <opencv/cv.h>

#import "UIView+SaveToImage.h"


@class AnonymousOverlayView;

@interface AnonymousViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
	AVCaptureSession *session;
	
	IBOutlet UIView *previewView;
	IBOutlet AnonymousOverlayView *overlayView;	
	IBOutlet UIButton *takePictureButton;	

	BOOL processingImage;
	
	SystemSoundID alertSoundID;
	
	CvHaarClassifierCascade* cascade;
	CvMemStorage* storage;
	
	IplImage *test_image;
	IplImage *small_image;
	IplImage *gray; 
	
	UIImage *previewImage;
	
	NSDate *start;
	
	CGRect previousFace1;
	CGRect previousFace2;
	int notFoundCount;
	
}

@property (nonatomic, retain) UIView *previewView;
@property (nonatomic, retain) UIImage *previewImage;
@property (nonatomic, retain) AnonymousOverlayView *overlayView;
@property (nonatomic, retain) NSDate *start;

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer;
- (IBAction)saveImage;

@end