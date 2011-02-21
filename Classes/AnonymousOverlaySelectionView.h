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
@class AnonymousOverlayAddView;

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
    
    int ID;
}

@property (nonatomic) OverlayItemState state;
@property (nonatomic) BOOL isSelected;
@property (nonatomic) int ID;


- (AnonymousOverlay *)overlay;
+ (id)anonymousOverlayItemWithOverlay:(AnonymousOverlay *)anOverlay;

@end


#pragma mark -

@interface AnonymousOverlaySelectionView : UIViewController {
	IBOutlet UIView *toolBar;
	IBOutlet UIButton *cancelButton;
	IBOutlet UIScrollView *scrollView;
    
    UIButton *addFromGoogleButton;
	
	float overlayItemMargin;
	float toolBarHeight;
	
	NSArray * dataSource;
	
	BOOL isInEditMode;
}

- (void)reloadData;

#pragma mark OverlayButton Functions

- (void)editOverlayItem:(AnonymousOverlayItem *)item;
- (void)selectOverlayItem:(AnonymousOverlayItem *)item;

- (void)editOverlayItemWithID:(int)theID;
- (void)selectOverlayItemWithID:(int)theID;

#pragma mark Toolbar Functions

- (IBAction)dismiss;
- (IBAction)toggleEdit;
- (IBAction)addNewOverlayItem;

@end