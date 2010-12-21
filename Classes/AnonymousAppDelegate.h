#import <UIKit/UIKit.h>

@class AnonymousViewController;

@interface AnonymousAppDelegate : NSObject <UIApplicationDelegate> {
	IBOutlet UIWindow *window;
	IBOutlet AnonymousViewController *viewController;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) AnonymousViewController *viewController;
@end