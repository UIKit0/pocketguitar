#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GraphicsServices/GraphicsServices.h>
#import "GuitarView.h"
#import "SettingsView.h"

@interface GuitarApp : UIApplication {
	UIWindow *window;
	UIView *mainView;
	GuitarView *guitarView;
	SettingsView *settingsView;
	UITransitionView *transition;
}
@end
