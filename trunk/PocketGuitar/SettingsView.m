//
//  SettingsView.m
//
//  Created by shinya on 07/12/31.
//

#import "SettingsView.h"

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
	[about appendString:@"<h3>PocketGuitar 0.1</h3>"];
	[about appendString:@"<div>http://code.google.com/p/pocketguitar/</div>"];
	[about appendString:@"<div>Copyright (C) 2008 Shinya Kasatani [kasatani at gmail.com]</div>"];
	[about appendString:@"<hr/>"];
	[about appendString:@"<div>PocketGuitar uses following sample packs from the Freesound Project: http://freesound.iua.upf.edu/. These samples are licensed under Creative Commons Sampling Plus 1.0 license.</div>"];
	[about appendString:@"<ul><li>643_SpeedY_Distorted_Guitar_Single_Notes</li><li>2774_Corsica_S_Old_Fender_P_Bass</li></ul>"];
	[about appendString:@"<hr/>"];
	[about appendString:@"<div>PocketGuitar uses The Synthesis ToolKit in C++ (STK): http://ccrma.stanford.edu/software/stk/"];
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
	UIPreferencesTableCell *instrumentCell;
	UIPreferencesTableCell *aboutCell;
}
@end

@implementation MainSettingsView

-(void)reloadData {
	[instrumentCell setValue:[[[self parent] selectedInstrument] name]];
	[super reloadData];
}

-(id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame backTitle:@"Back"];
	
	instrumentCell = [[UIPreferencesTableCell alloc] init];
	[instrumentCell setTitle:@"Instrument"];
	[instrumentCell setShowDisclosure:YES];
	[instrumentCell setAction:@selector(chooseInstrument)];

	aboutCell = [[UIPreferencesTableCell alloc] init];
	[aboutCell setTitle:@"About"];
	
	return self;
}

- (void)tableRowSelected:(NSNotification*)notification {
	NSLog(@"tableRowSelected: row=%d", [_table selectedRow]);
	switch ([_table selectedRow]) {
	case 1:
		[[self parent] chooseInstrument];
		break;
	case 3:
		[_parent about];
		break;
	}
}

- (void)navigationBar:(UINavigationBar*)bar buttonClicked:(int)which {
	[[self parent] saveSettings];
}

- (int)numberOfGroupsInPreferencesTable:(UIPreferencesTable*)aTable {
	return 2;
}

- (int)preferencesTable:(UIPreferencesTable *)aTable numberOfRowsInGroup:(int)group {
	return 1;
}

- (UIPreferencesTableCell*)preferencesTable:(UIPreferencesTable*)aTable cellForGroup:(int)group {
	return [[[UIPreferencesTableCell alloc] init] autorelease];
}

- (UIPreferencesTableCell*)preferencesTable:(UIPreferencesTable*)aTable cellForRow:(int)row inGroup:(int)group {
	switch (group) {
	case 0:
		return instrumentCell;
	case 1:
		return aboutCell;
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
-(id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	mainView = [[MainSettingsView alloc] initWithFrame:frame];
	[mainView setParent:self];
	instrumentsView = [[InstrumentsView alloc] initWithFrame:frame];
	[instrumentsView setParent:self];
	aboutView = [[AboutView alloc] initWithFrame:frame];
	[(SettingsSubView*)aboutView setParent:self];
	//[self addSubview:instrumentsView];
	//[self addSubview:instrumentsView];
	selectedInstrument = [InstrumentFactory defaultFactory];

	[self addSubview:mainView];
	[mainView reloadData];
	
	return self;
}

- (InstrumentFactory*)selectedInstrument {
	return selectedInstrument;
}

- (void)setSelectedInstrument:(InstrumentFactory*)instrument {
	selectedInstrument = instrument;
}

- (void)chooseInstrument {
	[instrumentsView reloadData];
	[self transition:1 toView:instrumentsView];
}

- (void)_instrumentChosen {
	[mainView reloadData];
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
	[delegate performSelector:@selector(settingsSaved)];
}

- (void)setDelegate:(id)d {
	delegate = d;
}
@end
