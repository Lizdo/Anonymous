//
//  UIView+SaveToImage.m
//  Anonymous
//
//  Created by Liz on 10-12-23.
//  Copyright 2010 StupidTent co. All rights reserved.
//

#import "UIView+SaveToImage.h"


@implementation UIView (SaveToImage)
- (UIImage*) renderToImage
{
	// IMPORTANT: using weak link on UIKit
	if(UIGraphicsBeginImageContextWithOptions != NULL)
	{
		UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
	} else {
		UIGraphicsBeginImageContext(self.frame.size);
	}
	
	[self.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();  
	return image;
}

@end