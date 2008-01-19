//
//  Guitar.m
//  PocketGuitar
//
//  Created by shinya on 08/01/14.
//

#include <Voicer.h>
#include <PRCRev.h>
#include <Chorus.h>
#include <NRev.h>
#include <JCRev.h>

#import "Guitar.h"
#import "InstrumentFactory.h"

#define A_FREQ 110.0

class VoicerManagingInstruments : public Voicer {
public:
	VoicerManagingInstruments(StkFloat decayTime);
	~VoicerManagingInstruments();
	StkFloat fastTick();
	void clearInstruments();
};

VoicerManagingInstruments::VoicerManagingInstruments(StkFloat decayTime) : Voicer(decayTime) {
}

VoicerManagingInstruments::~VoicerManagingInstruments() {
	clearInstruments();
}

StkFloat VoicerManagingInstruments::fastTick() {
  lastOutput_ = 0.0;
  int size = voices_.size();
  int i;
  for (i = 0; i < size; i++) {
	Voicer::Voice voice = voices_[i];
    if ( voice.sounding != 0 ) {
      lastOutput_ += voice.instrument->tick();
    }
	if ( voice.sounding < 0 ) {
      voice.sounding++;
	  if ( voice.sounding == 0 )
        voice.noteNumber = -1;
    }
  }
  return lastOutput_;
}

void VoicerManagingInstruments::clearInstruments() {
	std::vector<Voicer::Voice>::iterator i;
	for (i = voices_.begin(); i != voices_.end(); i++) {
		delete (*i).instrument;
	}
	voices_.clear();
}

@implementation Finger
- (float)fret {
	// dummy implementation
	return 0;
}
@end

@implementation PluckedString

- (id)initWithFrequency:(float)freq voicer:(Voicer*)v channel:(int)ch {
	frequency = freq;
	voicer = v;
	channel = ch;
	tag = -1;
	baseNote = 12.0 * log(freq / 220) / log(2.0) + 57;
	fingers = [[NSMutableArray alloc] initWithCapacity:10];
	return self;
}

- (void)setFret:(float)f {
	if (tag >= 0 && f != fret) {
		voicer->pitchBend(tag, 64.0 + (f - pluckedFret) * 64 / 12);
	}
	fret = f;
}

- (float)fret {
	return fret;
}

- (void)pluck {
//	printf("pluck at %f %f\n", fret, baseNote+fret);
	pluckedFret = fret;
	voicer->pitchBend(tag, 64.0);
	tag = voicer->noteOn(baseNote + fret, 60, channel);
}

- (void)mute {
	if (tag >= 0) {
		voicer->noteOff(tag, 100);
		tag = -1;
	}
}

- (void)addFinger:(Finger*)f {
	unsigned i = 0;
	for (i = 0; i < [fingers count]; i++) {
		if ([[fingers objectAtIndex:i] fret] > [f fret]) {
			break;
		}
	}
//	printf("addFinger %d %d\n", i, [fingers count]);
	if (i < [fingers count]) {
		[fingers insertObject:f atIndex:i];
	} else {
		[fingers addObject:f];
		fret = [f fret];
		if (tag >= 0) {
			if (pluckedFret > 0) {
				voicer->pitchBend(tag, 64 + (fret - pluckedFret) * 64 / 12);
			} else {
				[self mute];
			}
		}
//		printf("fret %f\n", fret);
	}
}

- (BOOL)isLastFinger:(Finger*)f {
	return (f == [fingers lastObject]);
}

- (void)removeFinger:(Finger*)f {
	BOOL last = (f == [fingers lastObject]);
	[fingers removeObject:f];
//	if ([f fret] == fret) {
	if (last) {
		fret = [fingers count] > 0 ? [[fingers lastObject] fret] : 0;
		if (fret == 0) {
			[self mute];
		} else if (tag >= 0) {
			voicer->pitchBend(tag, 64 + (fret - pluckedFret) * 64 / 12);
		}
	}
}

@end

@implementation Guitar
- (void)fillBuffer:(AudioSample*)buffer frames:(int)frames {
	[_lock lock];
    int i;
    for (i = 0; i < frames; i++){
//		float sample = _effect->tick(_voicer->tick() * 2) * _volume;
		float sample = ((VoicerManagingInstruments*)_voicer)->fastTick() * 0.5 * _volume;
		if (sample < -1.0) {
			sample = -1.0;
		} else if (sample > 1.0) {
			sample = 1.0;
		}
		AudioSample value = sample * 32767;
		*(buffer++) = value; // L
		*(buffer++) = value; // R
    }
	[_lock unlock];
}

static float stringNotes[] = {-5, 0, 5, 10, 14, 19};


- (id)init {
	Stk::setSampleRate(SAMPLING_RATE);
	_volume = 0.8;
	_voicer = new VoicerManagingInstruments(1.0);
//	_effect = new PRCRev(0.5);
	_lock = [[NSLock alloc] init];
//	_effect = new Chorus();
	int i;
	for (i = 0; i < CHANNELS; i++) {
		_strings[i] = [[PluckedString alloc] initWithFrequency:(A_FREQ * pow(2.0, stringNotes[i] / 12)) voicer:_voicer channel:i];
	}
	return self;
}

- (void)reloadInstruments:(InstrumentFactory*)factory {
	[_lock lock];
	printf("reload\n");
	((VoicerManagingInstruments*)_voicer)->clearInstruments();
	printf("cleared\n");
	int i;//, j;
	for (i = 0; i < CHANNELS; i++) {
		//for (j = 0; j < 2; j++) { // 2 instruments per channel
			Instrmnt *instr = [factory newInstrumentWithBaseFrequency:_strings[i]->frequency];
			_voicer->addInstrument(instr, i);
		//}
	}
	NSLog(@"reloadInstruments done");
	[_lock unlock];
}

- (PluckedString*)stringAtIndex:(int)i {
	return _strings[i];
}

- (void)setVolume:(float)volume {
	_volume = volume;
}
@end
