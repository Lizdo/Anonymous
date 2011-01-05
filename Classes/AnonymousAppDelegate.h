#import <UIKit/UIKit.h>

@class AnonymousViewController;
@class AnonymousOverlay;

@interface AnonymousAppDelegate : NSObject <UIApplicationDelegate> {
	IBOutlet UIWindow *window;
	IBOutlet AnonymousViewController *viewController;
	
	NSMutableArray * overlays;
}

@property (nonatomic, retain) NSMutableArray * overlays;
@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) AnonymousViewController *viewController;


- (AnonymousOverlay *)selectedOverlay;
- (void)save;
- (NSString *)overlayFilePath;

@end