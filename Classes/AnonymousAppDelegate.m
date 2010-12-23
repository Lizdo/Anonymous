#import "AnonymousAppDelegate.h"
#import "AnonymousViewController.h"

@implementation AnonymousAppDelegate
@synthesize window;
@synthesize viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	// Make it full screen
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
	viewController.view.frame = window.frame;
    [window addSubview:viewController.view];
	[window makeKeyAndVisible];
	
}

- (void)dealloc {
    [viewController release];
	[window release];
	[super dealloc];
}
@end