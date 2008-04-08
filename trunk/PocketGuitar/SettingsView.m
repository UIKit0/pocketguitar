//
//  SettingsView.m
//
//  Created by shinya on 07/12/31.
//

#import "SettingsView.h"
#import "FretboardEditor.h"
#import "Guitar.h"

#import <UIKit/CDStructures.h>
#import <UIKit/UISwitchControl.h>
#import <Celestial/AVSystemController.h>

#define POCKETGUITAR_VERSION @"0.2.1"

@interface SettingsSubView : UIView {
	UIPreferencesTable *_table;
	SettingsView *_parent;
	UINavigationBar *_navBar;
}
@end

@implementation SettingsSubView
-(SettingsView*)parent {
//	(SettingsView*)[self superview];
	return _parent;
}

-(void)reloadData {
	[_table reloadData];
}

-(void)setParent:(SettingsView*)p {
	_parent = p;
}

-(id)initWithFrame:(CGRect)frame backTitle:(NSString*)backTitle {
	self = [super initWithFrame:frame];
	CGSize navSize = [UINavigationBar defaultSize];
	
	_navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, navSize.height)];
	[_navBar showButtonsWithLeftTitle:backTitle rightTitle:nil leftBack:YES];
	[_navBar setBarStyle:5]; // This sets the color and look of the navigation bar.
	[_navBar setDelegate:self];	

	_table = [[UIPreferencesTable alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y + navSize.height, frame.size.width, frame.size.height - navSize.height)];
	[_table setDataSource:self];
	[_table setDelegate:self];

	[self addSubview:_navBar];
	[self addSubview:_table];
	
	return self;
}

- (int)numberOfGroupsInPreferencesTable:(UIPreferencesTable*)aTable {
	return 0;
}

- (int)preferencesTable:(UIPreferencesTable *)aTable numberOfRowsInGroup:(int)group {
	return 0;
}

@end

@interface AboutView : SettingsSubView {
	UITextView *_textView;
}
@end

@implementation AboutView
-(id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame backTitle:@"Settings"];
	CGSize navSize = [UINavigationBar defaultSize];
	_textView = [[UITextView alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y + navSize.height, frame.size.width, frame.size.height - navSize.height)];
	NSMutableString *about = [[NSMutableString alloc] init];
	[about appendString:@"<h3>PocketGuitar "];
	[about appendString:POCKETGUITAR_VERSION];
	[about appendString:@"</h3>"];
	[about appendString:@"<div>http://code.google.com/p/pocketguitar/</div>"];
	[about appendString:@"<div>Copyright (C) 2008 Shinya Kasatani [kasatani at gmail.com]</div>"];
	// TODO credits
	[about appendString:@"<hr/>"];
	[about appendString:@"<div>PocketGuitar uses following sample packs from the Freesound Project: http://freesound.iua.upf.edu/. These samples are licensed under Creative Commons Sampling Plus 1.0 license.</div>"];
	[about appendString:@"<ul>"];
	[about appendString:@"<li>\"Distorted Guitar Single Notes\" by SpeedY</li>"];
	[about appendString:@"<li>\"AcousticElectricGuitarOpenStrings\" by casualdave</li>"];
	[about appendString:@"<li>\"Old Fender P-Bass\" by Corsica_S</li>"];
	[about appendString:@"</ul>"];
	[about appendString:@"<hr/>"];
	[about appendString:@"<div>PocketGuitar uses The Synthesis ToolKit in C++ (STK) by Perry R. Cook and Gary P. Scavone: http://ccrma.stanford.edu/software/stk/"];
	[_textView setHTML:about];
	[_textView setEditable:NO];
	[_textView setTextSize:13];
	[self addSubview:_textView];
	NSLog(@"init about");
	return self;
}

- (void)navigationBar:(UINavigationBar*)bar buttonClicked:(int)which {
	[[self parent] closeAbout];
	NSLog(@"closeAbout");
}
@end

@interface InstrumentsView : SettingsSubView {
	NSMutableArray *instrumentCells;
}
@end

@implementation InstrumentsView
-(id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame backTitle:@"Settings"];

	NSEnumerator *instruments = [[InstrumentFactory allInstruments] objectEnumerator];
	instrumentCells = [[NSMutableArray alloc] initWithCapacity:10];
	InstrumentFactory *factory;
	while ((factory = [instruments nextObject])) {
		UIPreferencesTableCell *cell = [[UIPreferencesTableCell alloc] init];
		[cell setTitle:[factory name]];
		[cell setChecked:YES];
		[instrumentCells addObject:cell];
		NSLog([cell title]);
	}
	
	return self;
}

- (void)navigationBar:(UINavigationBar*)bar buttonClicked:(int)which {
	[[self parent] _instrumentChosen];
}

- (int)numberOfGroupsInPreferencesTable:(UIPreferencesTable*)aTable {
	return 1;
}

- (int)preferencesTable:(UIPreferencesTable *)aTable numberOfRowsInGroup:(int)group {
	return [instrumentCells count];
}

- (UIPreferencesTableCell*)preferencesTable:(UIPreferencesTable*)aTable cellForGroup:(int)group {
	return [[[UIPreferencesTableCell alloc] init] autorelease];
}

- (UIPreferencesTableCell*)preferencesTable:(UIPreferencesTable*)aTable cellForRow:(int)row inGroup:(int)group {
	return [instrumentCells objectAtIndex:row];
}

- (BOOL)table:(UITable*)table canSelectRow:(int)row {
	return YES;
}

- (void)reloadData {
	InstrumentFactory *instrument = [[self parent] selectedInstrument];
	NSEnumerator *cells = [instrumentCells objectEnumerator];
	UIPreferencesTableCell *cell;
	while ((cell = [cells nextObject])) {
		if ([[cell title] isEqualToString:[instrument name]]) {
			[cell setChecked:YES];
		} else {
			[cell setChecked:NO];
		}
	}
	[super reloadData];
}

- (void)tableRowSelected:(NSNotification*)notification {
	int selected = [_table selectedRow] - 1;
	[[self parent] setSelectedInstrument:[[InstrumentFactory allInstruments] objectAtIndex:selected]];
	[self reloadData];
	[[instrumentCells objectAtIndex:selected] setSelected:NO withFade:YES];
}

@end

@interface MainSettingsView : SettingsSubView {
	UIPreferencesTableCell *_instrumentCell;
	UIPreferencesTableCell *_editFretboardCell;
	UIPreferencesTableCell *_leftHandedCell;
	UIPreferencesTableCell *_systemVolumeCell;
	UIPreferencesTableCell *_aboutCell;
	UISwitchControl *_leftHandedSwitch;
	UISliderControl *_systemVolumeSlider;
	float _initialSystemVolume;
}
@end

@implementation MainSettingsView

-(void)reloadData {
	[_instrumentCell setValue:[[[self parent] selectedInstrument] name]];
	[_leftHandedSwitch setValue:[[[self parent] guitar] leftHanded]];
	
	NSString *name;
	AVSystemController *avsc = [AVSystemController sharedAVSystemController];
	[avsc getActiveCategoryVolume:&_initialSystemVolume andName:&name];
	[_systemVolumeSlider setValue:_initialSystemVolume];
	
	[super reloadData];
}

-(id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame backTitle:@"Back"];
	
	_instrumentCell = [[UIPreferencesTableCell alloc] init];
	[_instrumentCell setTitle:@"Instrument"];
	[_instrumentCell setShowDisclosure:YES];

	_editFretboardCell = [[UIPreferencesTableCell alloc] init];
	[_editFretboardCell setTitle:@"Edit Fretboard"];
	[_editFretboardCell setShowDisclosure:YES];
	
	_leftHandedCell = [[UIPreferencesTableCell alloc] init];
	[_leftHandedCell setTitle:@"Left-handed"];
	[_leftHandedCell setShowSelection:NO];
	
	_leftHandedSwitch = [[UISwitchControl alloc] initWithFrame:CGRectMake(208, 9, 60, 25)];
	[_leftHandedCell addSubview:_leftHandedSwitch];
	
	_systemVolumeCell = [[UIPreferencesTableCell alloc] init];
	[_systemVolumeCell setTitle:@"System Volume"];
	[_systemVolumeCell setShowSelection:NO];
	
	_systemVolumeSlider = [[UISliderControl alloc] initWithFrame:CGRectMake(170, 10, 130, 25)];
	[_systemVolumeSlider setMinValue:0.0];
	[_systemVolumeSlider setMaxValue:1.0];
	[_systemVolumeSlider addTarget:self action:@selector(changeVolume) forEvents:1|4]; // mouseDown | mouseDragged
	[_systemVolumeCell addSubview:_systemVolumeSlider];
	
	_aboutCell = [[UIPreferencesTableCell alloc] init];
	[_aboutCell setTitle:@"About"];
	[_aboutCell setShowDisclosure:YES];
	
	return self;
}

- (void)updateSystemVolume {
	float volume = [_systemVolumeSlider value];
	if (_initialSystemVolume != volume) {
		NSLog(@"changing volume from %f to %f", _initialSystemVolume, volume);
		[[AVSystemController sharedAVSystemController] setActiveCategoryVolumeTo:volume];
		[AudioOutput initSystemVolume];
	}
}

- (void)changeVolume {
}

- (BOOL)leftHanded {
	return (BOOL)[_leftHandedSwitch value];
}

- (void)tableRowSelected:(NSNotification*)notification {
	NSLog(@"tableRowSelected: row=%d", [_table selectedRow]);
	switch ([_table selectedRow]) {
	case 1:
		[[self parent] chooseInstrument];
		break;
	case 2:
		[[self parent] editFretboard];
		break;
		break;
	case 7:
		[_parent about];
		break;
	}
}

- (void)navigationBar:(UINavigationBar*)bar buttonClicked:(int)which {
	[[self parent] saveSettings];
}

- (int)numberOfGroupsInPreferencesTable:(UIPreferencesTable*)aTable {
	return 3;
}

- (int)preferencesTable:(UIPreferencesTable *)aTable numberOfRowsInGroup:(int)group {
	switch (group) {
	case 0:
		return 3;
	case 1:
		return 1;
	case 2:
		return 1;
	}
}

- (UIPreferencesTableCell*)preferencesTable:(UIPreferencesTable*)aTable cellForGroup:(int)group {
	return [[[UIPreferencesTableCell alloc] init] autorelease];
}

- (UIPreferencesTableCell*)preferencesTable:(UIPreferencesTable*)aTable cellForRow:(int)row inGroup:(int)group {
	switch (group) {
	case 0:
		switch (row) {
		case 0:
			return _instrumentCell;
		case 1:
			return _editFretboardCell;
		case 2:
			return _leftHandedCell;
		}
	case 1:
		return _systemVolumeCell;
	case 2:
		return _aboutCell;
	}
}

- (BOOL)preferencesTable:(UIPreferencesTable*)aTable isLabelGroup:(int)group {
	return NO;
}

- (float)preferencesTable:(UIPreferencesTable*)table heightForRow:(int)row inGroup:(int)group withProposedHeight:(float)proposed {
	return proposed;
}
@end

@implementation SettingsView
-(id)initWithFrame:(CGRect)frame andGuitar:(Guitar*)guitar {
	self = [super initWithFrame:frame];
	_guitar = guitar;
	
	mainView = [[MainSettingsView alloc] initWithFrame:frame];
	[mainView setParent:self];
	instrumentsView = [[InstrumentsView alloc] initWithFrame:frame];
	[instrumentsView setParent:self];
	
	fretboardEditor = [[FretboardEditor alloc] initWithFrame:frame];
	[fretboardEditor setFretboard:[_guitar fretboard]];
	[fretboardEditor setDelegate:self];
	
	aboutView = [[AboutView alloc] initWithFrame:frame];
	[(SettingsSubView*)aboutView setParent:self];
	
	//[self addSubview:instrumentsView];
	//[self addSubview:instrumentsView];
	selectedInstrument = [guitar instrument];

	[self addSubview:mainView];
	[mainView reloadData];
	
	return self;
}

- (void)reload {
	[mainView reloadData];
}

- (InstrumentFactory*)selectedInstrument {
	return selectedInstrument;
}

- (void)setSelectedInstrument:(InstrumentFactory*)instrument {
	selectedInstrument = instrument;
}

- (void)editFretboard {
	[self transition:1 toView:fretboardEditor];
}

- (void)chooseInstrument {
	[instrumentsView reloadData];
	[self transition:1 toView:instrumentsView];
}

- (void)_instrumentChosen {
	[mainView reloadData];
	[self transition:2 toView:mainView];
}

- (void)fretboardEdited {
	[[_guitar fretboard] save];
	[self transition:2 toView:mainView];
}


- (void)about {
	[self transition:1 toView:aboutView];
}

- (void)closeAbout {
	NSLog(@"closeAbout2");
	[mainView reloadData];
	[self transition:2 toView:mainView];
}

- (void)saveSettings {
	[_guitar setInstrument: selectedInstrument];
	[_guitar setLeftHanded: [mainView leftHanded]];
	[mainView updateSystemVolume];
	[_guitar saveSettings];
	[delegate performSelector:@selector(settingsSaved)];
}

- (void)setDelegate:(id)d {
	delegate = d;
}

- (Guitar*)guitar {
	return _guitar;
}
@end
