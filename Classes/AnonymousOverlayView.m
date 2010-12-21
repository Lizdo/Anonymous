//
//  AnonymousOverlayView.m
//  Anonymous
//
//  Created by Liz on 10-12-19.
//  Copyright 2010 StupidTent co. All rights reserved.
//

#import "AnonymousOverlayView.h"

#define EnlargeScale 1.5

CGRect enlargeRect(CGRect r){
	CGPoint midPoint = CGPointMake(r.origin.x+r.size.width/2, r.origin.y+r.size.height/2);
	return CGRectMake(midPoint.x-r.size.width*EnlargeScale/2, midPoint.y-r.size.height*EnlargeScale/2, 
					   r.size.width*EnlargeScale, r.size.height*EnlargeScale);
}


@implementation AnonymousOverlayView

@synthesize rects, overlayImage;

// The view is created from interface builder
- (id)initWithCoder:(NSCoder *)decoder{
	self = [super initWithCoder:decoder];
    if (self) {
        // Create 10 slots for potential faces
		self.rects = [NSMutableArray arrayWithCapacity:10];
		for (int i = 0; i < 10; i++) {
			[rects addObject:[NSValue valueWithCGRect:CGRectZero]];
		}
		// Default Overlay
		self.overlayImage = [UIImage imageNamed:@"laughing_man.png"];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef contextRef = UIGraphicsGetCurrentContext();
	CGContextClearRect(contextRef, rect);
	
	CGContextSetLineWidth(contextRef, 4);
	CGContextSetRGBStrokeColor(contextRef, 0.0, 0.0, 1.0, 0.5);

	
	//Draw the rects
	for (id object in rects) {
		CGRect rect = [object CGRectValue];
		
		if (!CGRectEqualToRect(rect,CGRectZero)) {
			if(overlayImage) {
				CGContextDrawImage(contextRef, enlargeRect(rect), overlayImage.CGImage);
			} else {
				CGContextStrokeRect(contextRef, rect);
			}
		}
	}
}




- (void)dealloc {
	[rects removeAllObjects];
	rects = nil;
	overlayImage = nil;
    [super dealloc];
}


@end
