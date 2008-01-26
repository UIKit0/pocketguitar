//
//  Guitar.h
//
//  Created by shinya on 08/01/14.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "InstrumentFactory.h"
#import "AudioOutput.h"
#import "Fretboard.h"

#ifndef STK_VOICER_H
@class Instrmnt;
@class Voicer;
@class Effect;
#endif

#define STRINGS 6
#define CHANNELS STRINGS

@class Guitar;

@interface Finger : NSObject {
}
-(float) fret;
@end

@interface PluckedString : NSObject {
	float baseNote;
	float fret;
	float pluckedFret;
	Voicer *voicer;
	int channel;
	long tag;
	NSMutableArray *fingers;
	@public
	float frequency;
	float _pitchBend;
	Guitar *_guitar;
}

- (void)addFinger:(Finger*)f;
- (void)pluck;
- (void)mute;
- (BOOL)isLastFinger:(Finger*)f;
- (void)removeFinger:(Finger*)f;
- (void)setFret:(float)f;
- (void)pitchBend:(float)f;
- (float)fret;

@end

@interface Guitar : AudioOutput {
	float _volume;
	Voicer *_voicer;
	Effect *_effect;
	PluckedString *_strings[STRINGS];
	NSLock *_lock;
	Fretboard *_fretboard;
	InstrumentFactory *_instrument;
	BOOL _leftHanded;
}

- (id)initWithRect:(CGRect)rect;
- (PluckedString*)stringAtIndex:(int)i;
- (void)reloadSettings;
- (void)saveSettings;
- (void)saveVolume;
- (float)volume;
- (void)setVolume:(float)volume;
- (Fretboard*)fretboard;
- (InstrumentFactory*)instrument;
- (void)setInstrument:(InstrumentFactory*)instrmnt;
- (BOOL)leftHanded;
- (void)setLeftHanded:(BOOL)leftHanded;
- (void)lock;
- (void)unlock;

@end
