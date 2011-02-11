//
//  AnonymousOverlayView.m
//  Anonymous
//
//  Created by Liz on 10-12-19.
//  Copyright 2010 StupidTent co. All rights reserved.
//

#import "AnonymousOverlayView.h"

#define DefaultEnlargeScale 1.5

#pragma mark NSCoding for UIImage

@interface UIImage (NSCoding)
- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;
@end

@implementation UIImage (NSCoding)
- (id)initWithCoder:(NSCoder *)decoder {
	NSData *pngData = [decoder decodeObjectForKey:@"PNGRepresentation"];
	[self autorelease];
	self = [[UIImage alloc] initWithData:pngData];
	return self;
}
- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:UIImagePNGRepresentation(self) forKey:@"PNGRepresentation"];
}
@end


@implementation AnonymousOverlay

@synthesize image, offsetToFace, sizeRatio, isSelected;
@synthesize startingSizeRatio, startingOffsetToFace;

+ (id)AnonymousOverlayWithImage:(UIImage *)image{
	AnonymousOverlay * overlay = [[AnonymousOverlay alloc] init];
	overlay.image = image;
	overlay.offsetToFace = CGPointZero;
	overlay.sizeRatio = DefaultEnlargeScale;
	overlay.isSelected = NO;	
	return [overlay autorelease];
}

- (CGRect)overlayRectFromFaceRect:(CGRect)faceRect{
	CGPoint faceCenter = CGPointMake(CGRectGetMidX(faceRect),
									 CGRectGetMidY(faceRect));
	CGPoint center = CGPointMake(faceCenter.x + offsetToFace.x,
								 faceCenter.y + offsetToFace.y);
	float size = faceRect.size.width*sizeRatio;
	return CGRectMake(center.x - size/2.0f, center.y - size/2.0f,
					  size, size);
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)coder{
	[coder encodeObject:image forKey:@"image"];
	[coder encodeCGPoint:offsetToFace forKey:@"offsetToFace"];
	[coder encodeFloat:sizeRatio forKey:@"sizeRatio"];
	[coder encodeBool:isSelected forKey:@"isSelected"];
	
}

- (id)initWithCoder:(NSCoder *)coder{
	//NSObject does not support NSCoding
	if ((self = [super init])) {
		//retain image
        self.image = [coder decodeObjectForKey:@"image"];
		offsetToFace = [coder decodeCGPointForKey:@"offsetToFace"];
		sizeRatio = [coder decodeFloatForKey:@"sizeRatio"];
		isSelected = [coder decodeBoolForKey:@"isSelected"];
    }
    return (self);
}

#pragma mark Edit Functions
- (void)save{
	originalSizeRatio = sizeRatio;
	originalOffsetToFace = offsetToFace;
}

- (void)reset{
	sizeRatio = originalSizeRatio;
	offsetToFace = originalOffsetToFace;
}

@end



@implementation AnonymousOverlayView

@synthesize rects, overlay;

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
		self.overlay = [AnonymousOverlay AnonymousOverlayWithImage:[UIImage imageNamed:@"laughing_man.png"]];
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
			if(overlay) {
				//CGContextDrawImage(contextRef, , overlayImage.CGImage);
				[[overlay image] drawInRect:[overlay overlayRectFromFaceRect:rect]];
			} else {
				CGContextStrokeRect(contextRef, rect);
			}
		}
	}
}




- (void)dealloc {
	[rects removeAllObjects];
	rects = nil;
	overlay = nil;
    [super dealloc];
}


@end
