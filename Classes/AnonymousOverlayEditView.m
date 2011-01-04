//
//  AnonymousOverlayEditView.m
//  Anonymous
//
//  Created by Liz on 11-1-3.
//  Copyright 2011 StupidTent co. All rights reserved.
//

#import "AnonymousOverlayEditView.h"
#import "AnonymousOverlaySelectionView.h"


@implementation AnonymousOverlayEditView

@synthesize overlay;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	NSAssert(overlay != nil, @"No Overlay Set");
	// Draw the overlay at the correct offset/position
	faceRect = CGRectMake(150, 140, 120, 120);
	CGRect rect = [overlay overlayRectFromFaceRect:faceRect];
	imageView = [[UIImageView alloc]init];
	imageView.contentMode = UIViewContentModeScaleAspectFill;
	imageView.image = overlay.image;
	imageView.frame = rect;
	[self.view addSubview:imageView];
	
	// Save Overlay's initial state
	[overlay save];
	
	// Add gesture recognizer
	UIPinchGestureRecognizer * pinchRecognizer = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)]autorelease];
	[eventView addGestureRecognizer:pinchRecognizer];
	
	UIPanGestureRecognizer * panRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)]autorelease];
	[eventView addGestureRecognizer:panRecognizer];	
}


- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer{
	if (recognizer.state == UIGestureRecognizerStateBegan){
		overlay.startingSizeRatio = overlay.sizeRatio;
	}else if (recognizer.state == UIGestureRecognizerStateChanged) {
		overlay.sizeRatio = overlay.startingSizeRatio*recognizer.scale;
		imageView.frame = [overlay overlayRectFromFaceRect:faceRect];		
	}
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer{
	if (recognizer.state == UIGestureRecognizerStateBegan){
		overlay.startingOffsetToFace = overlay.offsetToFace;
	}else if (recognizer.state == UIGestureRecognizerStateChanged) {
		CGPoint offset = [recognizer translationInView:eventView];
		offset = CGPointMake(offset.x/overlay.sizeRatio, offset.y/overlay.sizeRatio);
		overlay.offsetToFace = CGPointMake(overlay.startingOffsetToFace.x + offset.x,
										   overlay.startingOffsetToFace.y + offset.y);
		imageView.frame = [overlay overlayRectFromFaceRect:faceRect];			
	}
}

- (IBAction)cancelAndReturn{
	[overlay reset];
	[((AnonymousOverlaySelectionView *)(self.parentViewController)) toggleEdit];	
	[self.parentViewController dismissModalViewControllerAnimated:YES];
}

- (IBAction)saveAndReturn{
	[overlay save];
	[((AnonymousOverlaySelectionView *)(self.parentViewController)) toggleEdit];	
	[self.parentViewController dismissModalViewControllerAnimated:YES];	
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
