//
//  AnonymousOverlaySelectionView.m
//  Anonymous
//
//  Created by Liz on 10-12-27.
//  Copyright 2010 StupidTent co. All rights reserved.
//

#import "AnonymousOverlaySelectionView.h"
#import "AnonymousViewController.h"
#import "AnonymousOverlayEditView.h"
#import "AnonymousOverlayAddView.h"

#import "AnonymousAppDelegate.h"

@implementation AnonymousOverlayItem

- (AnonymousOverlay *)overlay{
	return overlay;
}

- (void)setState:(OverlayItemState)newState{
	if (newState == OverlayItemStateNormal) {
		// Toggle Normal
		[UIView animateWithDuration:SlideAnimDuration animations:^{
			imageView.frame = CGRectMake(0, 0, OverlayItemSize, OverlayItemSize);
		}];
		// Add the normal Icon
		self.isSelected = overlay.isSelected;		
	}else if (newState == OverlayItemStateEdit) {
		// Toggle Edit
		[UIView animateWithDuration:SlideAnimDuration animations:^{
			imageView.frame = CGRectMake(0, 0, OverlayItemMinimalSize, OverlayItemMinimalSize);
		}];
		markerView.image = [UIImage imageNamed:@"EditMark.png"];
	}
	state = newState;
}


- (OverlayItemState)state{
	return state;
}

- (void)setIsSelected:(BOOL)newBool{
	if (newBool) {
		markerView.image = [UIImage imageNamed:@"RightMark.png"];
	}
	else {
		markerView.image = nil;
	}
	[self setNeedsDisplay];
	overlay.isSelected = newBool;
}

- (BOOL)isSelected{
	return overlay.isSelected;
}

+ (id)anonymousOverlayItemWithOverlay:(AnonymousOverlay *)anOverlay{
	AnonymousOverlayItem * item = [[AnonymousOverlayItem alloc] initWithFrame:CGRectMake(0, 0, OverlayItemSize, OverlayItemSize)];
	
	// Set Overlay
	[item setValue:anOverlay forKeyPath:@"overlay"];
	
	// Set ImageView
	UIImageView *imageView = [[[UIImageView alloc] initWithFrame:item.bounds]autorelease];
	imageView.image = [anOverlay image];
	[item addSubview:imageView];
	[item setValue:imageView forKeyPath:@"imageView"];
	
	// Set MarkerView
	CGRect markerRect = CGRectMake(item.bounds.size.width - OverlayItemMarkerSize,
								   item.bounds.size.height - OverlayItemMarkerSize,
								   OverlayItemMarkerSize,OverlayItemMarkerSize);
	UIImageView *markerView = [[[UIImageView alloc] initWithFrame:markerRect]autorelease];
	[item addSubview:markerView];
	[item setValue:markerView forKeyPath:@"markerView"];
	
	UITapGestureRecognizer * recognizer = [[[UITapGestureRecognizer alloc]initWithTarget:item action:@selector(handleTap)]autorelease];
	[item addGestureRecognizer:recognizer];
	
	return [item autorelease];
}

- (void)handleTap{
	if (state == OverlayItemStateNormal) {
		// Select Tapped Item
		[controller selectOverlayItem:self];
	}else if (state == OverlayItemStateEdit) {
		// Edit Tapped Item
		[controller editOverlayItem:self];
	}
}

@end

@interface AnonymousOverlaySelectionView(Private)

- (CGPoint)centerForItemID:(int)itemID;

@end



@implementation AnonymousOverlaySelectionView


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
	// TODO: Load overlays from the save file
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		//load from app delegate
		dataSource = ((AnonymousAppDelegate *)[UIApplication sharedApplication].delegate).overlays;
	}
	return self;
}

- (void)dealloc {
	[dataSource release];
    [super dealloc];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	// Layout the subviews
	NSAssert(dataSource.count > 0, @"Must have more than one overlays.");
	overlayItemMargin = (scrollView.frame.size.width - OverlayItemSize * ItemsPerRow)/(ItemsPerRow+1);
	toolBarHeight = toolBar.frame.size.height;
	
	for (int i = 0; i < dataSource.count; i++) {
		AnonymousOverlayItem * item = [AnonymousOverlayItem anonymousOverlayItemWithOverlay:[dataSource objectAtIndex:i]];
		[item setValue:self forKeyPath:@"controller"];				
		[scrollView addSubview:item];
		item.center = [self centerForItemID:i];	
		if (i == 0) {
			item.isSelected = YES;
		}
	}
	
    [super viewDidLoad];
	
    // Show status bar
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    
	// Hack to test search interface
	[self performSelector:@selector(addNewOverlayItem) withObject:self afterDelay:1];
}




- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


#pragma mark Handle Events

- (IBAction)toggleEdit{
	if (isInEditMode) {
		// Animation to dismiss cancel edit button
		[UIView animateWithDuration:SlideAnimDuration 
						 animations:^{cancelButton.center = CGPointMake(cancelButton.center.x, cancelButton.center.y + toolBarHeight);}
						 completion:^(BOOL finished){
							 [UIView animateWithDuration:SlideAnimDuration
											  animations:^{toolBar.center = CGPointMake(toolBar.center.x, toolBar.center.y - toolBarHeight);}];
						 }];
		for (UIView * item in scrollView.subviews) {
			if ([item isKindOfClass:[AnonymousOverlayItem class]]) {
				((AnonymousOverlayItem *)item).state = OverlayItemStateNormal;				
			}
		}
	}else {
		// Animation to dismiss the toolbar, bring cancel edit button back
		[UIView animateWithDuration:SlideAnimDuration 
						 animations:^{toolBar.center = CGPointMake(toolBar.center.x, toolBar.center.y + toolBarHeight);}
						 completion:^(BOOL finished){
							 [UIView animateWithDuration:SlideAnimDuration
											  animations:^{cancelButton.center = CGPointMake(cancelButton.center.x, cancelButton.center.y - toolBarHeight);}];
						 }];
		for (UIView * item in scrollView.subviews) {
			if ([item isKindOfClass:[AnonymousOverlayItem class]]) {
				((AnonymousOverlayItem *)item).state = OverlayItemStateEdit;				
			}
		}		
	}
	isInEditMode = !isInEditMode;
}

- (IBAction)dismiss{
	// remove self from parent view controller
	[(AnonymousViewController *)(self.parentViewController) resumeCapture];
	[self.parentViewController dismissModalViewControllerAnimated:YES];

}

- (void)addNewOverlayItem{
	AnonymousOverlayAddView * overlayAddController = [[AnonymousOverlayAddView alloc]initWithDefaultNib];
	[self presentModalViewController:overlayAddController animated:YES];
}

- (void)editOverlayItem:(AnonymousOverlayItem *)item{
	//self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	AnonymousOverlayEditView * overlayEditController = [[[AnonymousOverlayEditView alloc]initWithNibName:@"AnonymousOverlayEditView" bundle:nil]autorelease];
	overlayEditController.overlay = item.overlay;
	[self presentModalViewController:overlayEditController animated:YES];
}

- (void)selectOverlayItem:(AnonymousOverlayItem *)selectedItem{
	for (UIView * item in scrollView.subviews) {
		if ([item isKindOfClass:[AnonymousOverlayItem class]]) {
			if (selectedItem != item){
				((AnonymousOverlayItem *)item).isSelected = NO;
			}		
		}
	}
	selectedItem.isSelected = YES;
	
	//TODO: Set the current overlay here
}


#pragma mark Helper Functions

// 0 1 2
// 1  
// 2

- (CGPoint)centerForItemID:(int)itemID{
	int row = itemID/ItemsPerRow;
	int col = itemID - row*ItemsPerRow;
	return CGPointMake(col * (OverlayItemSize + overlayItemMargin) + overlayItemMargin + OverlayItemSize/2,
					   row * (OverlayItemSize + overlayItemMargin) + overlayItemMargin + OverlayItemSize/2);
}


@end
