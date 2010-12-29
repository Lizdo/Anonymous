//
//  AnonymousOverlaySelectionView.m
//  Anonymous
//
//  Created by Liz on 10-12-27.
//  Copyright 2010 StupidTent co. All rights reserved.
//

#import "AnonymousOverlaySelectionView.h"
#import "AnonymousViewController.h"

@implementation AnonymousOverlayItem

- (void)setState:(OverlayItemState)newState{
	if (newState == OverlayItemStateNormal) {
		//Toggle Normal
		[UIView animateWithDuration:SlideAnimDuration animations:^{
			imageView.frame = CGRectMake(0, 0, OverlayItemSize, OverlayItemSize);
		}];
		
	}else if (newState == OverlayItemStateEdit) {
		//Toggle Edit
		[UIView animateWithDuration:SlideAnimDuration animations:^{
			imageView.frame = CGRectMake(0, 0, OverlayItemMinimalSize, OverlayItemMinimalSize);
		}];		
	}
	state = newState;
}


- (OverlayItemState)state{
	return state;
}

+ (id)anonymousOverlayItemWithOverlay:(AnonymousOverlay *)anOverlay{
	AnonymousOverlayItem * item = [[AnonymousOverlayItem alloc] initWithFrame:CGRectMake(0, 0, OverlayItemSize, OverlayItemSize)];
	
	// Set Overlay
	[item setValue:anOverlay forKeyPath:@"overlay"];
	
	// Set ImageView
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:item.bounds];
	imageView.image = [anOverlay image];
	[item addSubview:imageView];
	[item setValue:imageView forKeyPath:@"imageView"];
	
	return [item autorelease];
}


@end

@interface AnonymousOverlaySelectionView(Private)

- (CGPoint)centerForItemID:(int)itemID;

@end



@implementation AnonymousOverlaySelectionView


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
	// TODO: Load overlays from the save file
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		dataSource = [[NSArray arrayWithObjects:[AnonymousOverlay AnonymousOverlayWithImage:[UIImage imageNamed:@"laughing_man.png"]],
					   [AnonymousOverlay AnonymousOverlayWithImage:[UIImage imageNamed:@"laughing_man.png"]],
					   [AnonymousOverlay AnonymousOverlayWithImage:[UIImage imageNamed:@"laughing_man.png"]],
					   nil
					   ] retain];
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
		[scrollView addSubview:item];
		item.center = [self centerForItemID:i];		
	}
	
    [super viewDidLoad];
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
