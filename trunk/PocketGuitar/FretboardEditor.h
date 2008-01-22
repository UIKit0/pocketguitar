//
//  FretboardEditor.h
//  PocketGuitar
//

#import <Foundation/Foundation.h>
#import <LayerKit/LayerKit.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <GraphicsServices/GraphicsServices.h>

#import "Fretboard.h"

@interface FretboardEditor : UIView {
	Fretboard *_fretboard;
	BOOL _draggingFrets;
	BOOL _draggingFretEnd;
	BOOL _draggingStrings;
	float _dragOffset;
	id _delegate;
}

- (void)setFretboard:(Fretboard *)fretboard;
- (void)setDelegate:(id)delegate;
@end
