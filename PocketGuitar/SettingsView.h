//
//  SettingsView.h
//
//  Created by shinya on 07/12/31.
//

#import <Foundation/Foundation.h>
#import <LayerKit/LayerKit.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIPreferencesTable.h>
#import <UIKit/UIPreferencesTableCell.h>
#import <CoreGraphics/CoreGraphics.h>
#import <GraphicsServices/GraphicsServices.h>

#import "InstrumentFactory.h"

@class InstrumentsView;
@class MainSettingsView;
@class FretboardEditor;
@class Fretboard;
@class Guitar;

@interface SettingsView : UITransitionView {
	MainSettingsView *mainView;
	UIPreferencesTable *table;
	InstrumentFactory* selectedInstrument;
	InstrumentsView *instrumentsView;
	FretboardEditor *fretboardEditor;
	Guitar *_guitar;
	UIView *aboutView;
	id delegate;
}

- (id)initWithFrame:(CGRect)frame andGuitar:(Guitar*)guitar;
- (void)setDelegate:(id)delegate;
- (InstrumentFactory*)selectedInstrument;
- (void)setSelectedInstrument:(InstrumentFactory*)instrument;
- (void)saveSettings;
- (void)chooseInstrument;
- (void)editFretboard;
- (void)_instrumentChosen;
- (void)about;
- (void)closeAbout;
- (Guitar*)guitar;
@end
