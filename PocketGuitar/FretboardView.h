//
//  FretboardView.h
//  PocketGuitar
//
//  Created by shinya on 08/04/02.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Fretboard.h"

#define VIEW_MAX_FRETS 12
#define VIEW_MAX_DOTS 4

@interface FretboardView : UIView {
	Fretboard *_fretboard;
	UIImageView *_fretViews[VIEW_MAX_FRETS];
	UIImageView *_stringViews[STRING_IMAGES];
	UIImageView *_dotViews[VIEW_MAX_DOTS];
	UIView *_shadingView;
	UIImageView *_backgroundView;
}

- (void)reloadFretboard;
- (void)setFretboard:(Fretboard*)fretboard;
@end
