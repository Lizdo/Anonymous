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
@interface AnonymousOverlay : NSObject{
	UIImage * image;
	CGPoint offsetToFace;
	float sizeRatio;
}

@property (nonatomic,retain) UIImage * image;
@property (nonatomic) CGPoint offsetToFace;
@property (nonatomic) float sizeRatio;

+ (id)AnonymousOverlayWithImage:(UIImage *)image;
- (CGRect)overlayRectFromFaceRect:(CGRect)faceRect;

@end

// Overlay View to draw the face
@interface AnonymousOverlayView : UIView {
	AnonymousOverlay * overlay;
	NSMutableArray * rects;
	
}

@property (nonatomic,retain) NSMutableArray * rects;
@property (nonatomic,retain) AnonymousOverlay * overlay;

@end


