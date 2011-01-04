//
//  AnonymousOverlayEditView.h
//  Anonymous
//
//  Created by Liz on 11-1-3.
//  Copyright 2011 StupidTent co. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnonymousOverlayView.h"

@interface AnonymousOverlayEditView : UIViewController {
	AnonymousOverlay * overlay;
	CGRect faceRect;
	
	IBOutlet UIView * eventView;
	UIImageView * imageView;
	
}


@property (nonatomic, assign) AnonymousOverlay * overlay;

- (IBAction)cancelAndReturn;
- (IBAction)saveAndReturn;

@end
