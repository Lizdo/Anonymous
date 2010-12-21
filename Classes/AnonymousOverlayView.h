//
//  AnonymousOverlayView.h
//  Anonymous
//
//  Created by Liz on 10-12-19.
//  Copyright 2010 StupidTent co. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AnonymousOverlayView : UIView {
	UIImage * overlayImage;
	NSMutableArray * rects;
	
}

@property (nonatomic,retain) NSMutableArray * rects;
@property (nonatomic,retain) UIImage * overlayImage;

@end
