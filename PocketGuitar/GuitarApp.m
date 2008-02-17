#import "GuitarApp.h"
#import "AudioOutput.h"

id GSColorCreateWithDeviceWhite(float f1, float f2);

typedef enum {
	kGSFontTraitRegular = 0,
    kGSFontTraitItalic = 1,
    kGSFontTraitBold = 2,
    kGSFontTraitBoldItalic = (kGSFontTraitBold | kGSFontTraitItalic)
} GSFontTrait;

id GSFontCreateWithName(char *name, GSFontTrait traits, float size);

@implementation GuitarApp

- (void)applicationDidFinishLaunching:(GSEventRef)event;
{
	// hide status bar
    [UIHardware _setStatusBarHeight:0.0f];
    [self setStatusBarMode:2 orientation:0 duration:0.0f fenceID:0];
	
    CGRect rect = [UIHardware fullScreenApplicationContentRect];
    rect.origin = CGPointZero;
    window = [[UIWindow alloc] initWithContentRect:rect];
	[window orderFront:self];
    [window makeKey:self];
	CGRect bounds = [window bounds];

	mainView = [[[UIView alloc] initWithFrame:bounds] autorelease];
    [window setContentView:mainView];
    [mainView setBackgroundColor:(CGColorRef)[(id)GSColorCreateWithDeviceWhite(0.0, 1.0) autorelease]];

	[AudioOutput initSystemVolume];
	
	transition = [[UITransitionView alloc] initWithFrame:[window bounds]];
	[mainView addSubview: transition];	
	
    guitarView = [[GuitarView alloc] initWithFrame:[window bounds]];
    [transition addSubview:guitarView];

	UIPushButton* pushButton = [[UIPushButton alloc] initWithTitle:@"Settings" autosizesToFit:NO];
	[pushButton setFrame: CGRectMake(0, 0, 100, 30)];
	[pushButton setDrawsShadow: YES];
	[pushButton setEnabled:YES];  //may not be needed
	[pushButton setStretchBackground:YES];
	[pushButton setTitleFont:(struct __GSFont*)GSFontCreateWithName("Helvetica", kGSFontTraitBold, 15.0f)];
	[pushButton addTarget:self action:@selector(showSettings) forEvents:1];

	[guitarView addSubview:pushButton];
	
	settingsView = [[SettingsView alloc] initWithFrame:[window bounds] andGuitar:[guitarView guitar]];
	[settingsView setDelegate:self];

    [window orderFront:nil];
    [window makeKey:nil];
}

- (void)showSettings {
	[settingsView reload];
	[transition transition:1 fromView:guitarView toView:settingsView];
	[settingsView setNeedsDisplay];
}

- (void)settingsSaved {
	NSLog(@"settingsSaved %@", guitarView);
	[[guitarView guitar] reloadSettings];
	[guitarView setNeedsDisplay];
	[transition transition:2 fromView:settingsView toView:guitarView];
}

- (void)applicationWillSuspend {
	[[guitarView guitar] saveVolume];
	[super applicationWillSuspend];
}

@end

