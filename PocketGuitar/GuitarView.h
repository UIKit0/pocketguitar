//
//  GuitarView.h
//
//  Created by shinya on 07/12/23.
//

#import <Foundation/Foundation.h>
#import <LayerKit/LayerKit.h>
#import <UIKit/UIKit.h>
#import <UIKit/UISliderControl.h>
#import <CoreGraphics/CoreGraphics.h>
#import <GraphicsServices/GraphicsServices.h>

#import "Guitar.h"

#define FINGER_SLOTS 10
#define MAX_FRETS 7

#import "InstrumentFactory.h"

//@class VolumeSliderView;

@interface GuitarView : UIView {
//	Oscillator *oscillators[OSCILLATORS];
//	Channel *channels[CHANNELS];
	Finger *fingers[FINGER_SLOTS];
	Guitar *_guitar;
	UISliderControl *sliderView;
}

- (int)stringIndexAt:(CGPoint)point;
- (PluckedString*)stringAt:(CGPoint)point;
- (PluckedString*)stringAtIndex:(int)index;
- (float)fretPositionAt:(int)index;
- (void)scanFingers:(GSEvent *)event;
- (Guitar*)guitar;

@end
