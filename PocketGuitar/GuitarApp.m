#import "GuitarApp.h"

id GSColorCreateWithDeviceWhite(float f1, float f2);

@implementation GuitarApp

- (void)applicationDidFinishLaunching:(GSEventRef)event;
{
    window = [[UIWindow alloc] initWithContentRect:[UIHardware fullScreenApplicationContentRect]];
	CGRect bounds = [window bounds];
	mainView = [[[UIView alloc] initWithFrame:bounds] autorelease];
    [window setContentView:mainView];
    [mainView setBackgroundColor:(CGColorRef)[(id)GSColorCreateWithDeviceWhite(0.0, 1.0) autorelease]];

	settingsView = [[SettingsView alloc] initWithFrame:[window bounds]];
	[settingsView setDelegate:self];

	AVSystemController *avsc = [AVSystemController sharedAVSystemController];
//	float volume;
//	NSString *name;
//	[avsc getActiveCategoryVolume:&volume andName:&name];
//	NSLog(@"volume=%f name=%@", volume, name);
	[avsc setActiveCategoryVolumeTo:0.7];
	transition = [[UITransitionView alloc] initWithFrame:[window bounds]];
	[mainView addSubview: transition];	
	
    guitarView = [[GuitarView alloc] initWithFrame:[window bounds]];
    [transition addSubview:guitarView];

	UIPushButton* pushButton = [[UIPushButton alloc] initWithTitle:@"Settings" autosizesToFit:NO];
	[pushButton setFrame: CGRectMake(0, 0, 100, 30)];
	[pushButton setDrawsShadow: YES];
	[pushButton setEnabled:YES];  //may not be needed
	[pushButton setStretchBackground:YES];
	[pushButton addTarget:self action:@selector(showSettings) forEvents:1];

	[guitarView addSubview:pushButton];
	
    [window orderFront:nil];
    [window makeKey:nil];
}

- (void)showSettings {
	[transition transition:1 fromView:guitarView toView:settingsView];
	[settingsView setNeedsDisplay];
}

- (void)settingsSaved {
	NSLog(@"settingsSaved %@", guitarView);
	[guitarView reloadInstruments:[settingsView selectedInstrument]];
	[transition transition:2 fromView:settingsView toView:guitarView];
}

@end

