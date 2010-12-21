//
//  AnonymousOverlayView.m
//  Anonymous
//
//  Created by Liz on 10-12-19.
//  Copyright 2010 StupidTent co. All rights reserved.
//

#import "AnonymousOverlayView.h"


@implementation AnonymousOverlayView

@synthesize rects;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
	CGContextRef contextRef = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(contextRef, 4);
	CGContextSetRGBStrokeColor(contextRef, 0.0, 0.0, 1.0, 0.5);
	
	//Draw the rects
	NSLog(@"Number of rects: %d", [rects count]);
	for (id object in rects) {
		CGRect rect = [object CGRectValue];
		//if(overlayImage) {
//			CGContextDrawImage(contextRef, rect, overlayImage.CGImage);
//		} else {
			CGContextStrokeRect(contextRef, rect);
		//}
	}
}


- (void)dealloc {
    [super dealloc];
}


@end
