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

#define OverlayItemSize 80
#define OverlayItemMinimalSize 70
#define OverlayItemMarkerSize 30

#define ItemsPerRow 3

#define SlideAnimDuration 0.3f

@class AnonymousOverlaySelectionView;

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
	UIImageView * markerView;
		
	AnonymousOverlaySelectionView * controller;
}

@property (nonatomic) OverlayItemState state;
@property (nonatomic) BOOL isSelected;

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

- (void)editOverlayItem:(AnonymousOverlayItem *)item;
- (void)selectOverlayItem:(AnonymousOverlayItem *)item;

#pragma mark Toolbar Functions

- (IBAction)dismiss;
- (IBAction)toggleEdit;

@end