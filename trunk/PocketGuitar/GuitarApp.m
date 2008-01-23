#import "GuitarApp.h"
#include "MobileMusicPlayer/MobileMusicPlayer.h"

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
    window = [[UIWindow alloc] initWithContentRect:[UIHardware fullScreenApplicationContentRect]];
	CGRect bounds = [window bounds];
	mainView = [[[UIView alloc] initWithFrame:bounds] autorelease];
    [window setContentView:mainView];
    [mainView setBackgroundColor:(CGColorRef)[(id)GSColorCreateWithDeviceWhite(0.0, 1.0) autorelease]];

	AVSystemController *avsc = [AVSystemController sharedAVSystemController];
	float volume;
	NSString *name;
	[avsc getActiveCategoryVolume:&volume andName:&name];
	NSLog(@"volume=%f name=%@", volume, name);
	NSLog(@"route=%@", [avsc routeForCategory:@"Audio/Video"]);
	
	int playbackState = PCGetPlaybackState();
	NSLog(@"state=%d", playbackState);

	if (kPlayerPlaying != playbackState) {
		[avsc setActiveCategoryVolumeTo:0.6];
		AVController *avc = [AVController avController];
		NSError *error;
		AVItem *silence = [[AVItem alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"silence" ofType:@"wav"] error:&error];
		[avc setCurrentItem:silence preservingRate:NO];
		[avc setCurrentTime:0.0];
		[avc play:nil];
		[avc pause];
//		[avc release];
/*	[avc setVolume:0.8];
//	[avc pause];
*/
	}
	
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

