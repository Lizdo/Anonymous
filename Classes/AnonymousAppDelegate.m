#import "AnonymousAppDelegate.h"
#import "AnonymousViewController.h"

#import "AnonymousOverlayView.h"

#define kOverlayFilePath @"overlays.plist"

@implementation AnonymousAppDelegate
@synthesize window;
@synthesize viewController;
@synthesize overlays;



- (void)applicationDidFinishLaunching:(UIApplication *)application {
	// Make it full screen
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
	viewController.view.frame = window.frame;
    [window addSubview:viewController.view];
	[window makeKeyAndVisible];
	
	// TODO: load the array from the disk on background thread
    [self performSelectorInBackground:@selector(loadOverlay) withObject:self];
}

- (void)loadOverlay{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    overlays = [NSKeyedUnarchiver unarchiveObjectWithFile:[self overlayFilePath]];
	if (overlays == nil) {
		// No valid object extracted, create a temp one
		overlays = [NSMutableArray arrayWithObject:[AnonymousOverlay AnonymousOverlayWithImage:[UIImage imageNamed:@"laughing_man.png"]]];
		// Select the first one
		((AnonymousOverlay *)[overlays objectAtIndex:0]).isSelected = YES;
	}
	
	[overlays retain];
    [pool release];
    
    // Post load complete notification
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"OverlayLoadedCompleteNotification" object:self];
    
}

- (NSString *)overlayFilePath{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
	NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:kOverlayFilePath];
}


- (void)applicationWillTerminate:(UIApplication *)application{
	[self save];
}

- (void)applicationWillResignActive:(UIApplication *)application{
	[self save];
}

- (AnonymousOverlay *)selectedOverlay{
	for (AnonymousOverlay * overlay in overlays) {
		if (overlay.isSelected == YES) {
			return overlay;
		}
	}
	NSLog(@"NO Object Selected, use the 1st one instead");
	return [overlays objectAtIndex:0];
}

- (void)removeOverlay:(AnonymousOverlay *)overlay{
    [overlays removeObject:overlay];
}


- (void)save{
	BOOL result = [NSKeyedArchiver archiveRootObject:overlays toFile:[self overlayFilePath]];
	if (result == NO) {
		NSLog(@"Failed to save file");
	}
}

- (void)dealloc {
	[overlays removeAllObjects];
	[overlays release];
	
    [viewController release];
	[window release];
	[super dealloc];
}
@end