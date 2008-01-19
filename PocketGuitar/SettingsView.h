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

@interface SettingsView : UITransitionView {
	MainSettingsView *mainView;
	UIPreferencesTable *table;
	InstrumentFactory* selectedInstrument;
	InstrumentsView *instrumentsView;
	UIView *aboutView;
	id delegate;
}

- (void)setDelegate:(id)delegate;
- (InstrumentFactory*)selectedInstrument;
- (void)setSelectedInstrument:(InstrumentFactory*)instrument;
- (void)saveSettings;

- (void)chooseInstrument;
- (void)_instrumentChosen;
- (void)about;
- (void)closeAbout;
@end
