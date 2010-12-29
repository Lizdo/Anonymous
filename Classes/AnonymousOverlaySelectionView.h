//
//  AnonymousOverlaySelectionView.h
//  Anonymous
//
//  - Pick an overlay
//  - Delete an overlay
//  - Add an overlay
//
//  Created by Liz on 10-12-27.
//  Copyright 2010 StupidTent co. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnonymousOverlayView.h"

#pragma mark -
#pragma mark OverlayItem Functions

#define OverlayItemSize 90
#define OverlayItemMinimalSize 70

#define ItemsPerRow 3

#define SlideAnimDuration 0.3f

typedef enum {
	OverlayItemStateNormal,
	OverlayItemStateEdit
}OverlayItemState;

#pragma mark -

@interface AnonymousOverlayItem : UIView
{
	AnonymousOverlay * overlay;
	OverlayItemState state;
	
	UIImageView * imageView;
}

@property (nonatomic) OverlayItemState state;

+ (id)anonymousOverlayItemWithOverlay:(AnonymousOverlay *)anOverlay;

@end


#pragma mark -

@interface AnonymousOverlaySelectionView : UIViewController {
	IBOutlet UIView *toolBar;
	IBOutlet UIButton *cancelButton;
	IBOutlet UIScrollView *scrollView;
	
	float overlayItemMargin;
	float toolBarHeight;
	
	NSArray * dataSource;
	
	BOOL isInEditMode;
}

#pragma mark OverlayButton Functions

- (void)editOverlayWithID:(int)overlayID;
- (void)deleteOverlayWithID:(int)overlayID;
- (void)addNewOverlay;

#pragma mark Toolbar Functions

- (IBAction)dismiss;
- (IBAction)toggleEdit;

@end