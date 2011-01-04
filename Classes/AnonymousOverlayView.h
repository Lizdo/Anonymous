//
//  AnonymousOverlayView.h
//  Anonymous
//
//  Created by Liz on 10-12-19.
//  Copyright 2010 StupidTent co. All rights reserved.
//

#import <UIKit/UIKit.h>

#define FaceSize 10.0f


// Container object for all the preview overlays
@interface AnonymousOverlay : NSObject <NSCoding>{
	UIImage * image;
	CGPoint offsetToFace;
	float sizeRatio;
	BOOL isSelected;
	
	CGPoint startingOffsetToFace;
	float startingSizeRatio;	
	
	CGPoint originalOffsetToFace;
	float originalSizeRatio;
}

@property (nonatomic,retain) UIImage * image;
@property (nonatomic) CGPoint offsetToFace;
@property (nonatomic) float sizeRatio;
@property (nonatomic) BOOL isSelected;

@property (nonatomic) CGPoint startingOffsetToFace;
@property (nonatomic) float startingSizeRatio;


+ (id)AnonymousOverlayWithImage:(UIImage *)image;
- (CGRect)overlayRectFromFaceRect:(CGRect)faceRect;

#pragma mark Edit Functions
- (void)save;
- (void)reset;

@end

// Overlay View to draw the face
@interface AnonymousOverlayView : UIView {
	AnonymousOverlay * overlay;
	NSMutableArray * rects;
	
}

@property (nonatomic,retain) NSMutableArray * rects;
@property (nonatomic,retain) AnonymousOverlay * overlay;

@end


