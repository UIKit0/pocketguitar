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

- (void)setFrequency:(float)freq {
	frequency = freq;
	baseNote = 12.0 * log(freq / 220) / log(2.0) + 57;
}

- (id)initWithFrequency:(float)freq voicer:(Voicer*)v channel:(int)ch {
	voicer = v;
	channel = ch;
	tag = -1;
	[self setFrequency:freq];
	fingers = [[NSMutableArray alloc] initWithCapacity:10];
	return self;
}

- (void)setFret:(float)f {
	if (tag >= 0 && f != fret) {
		voicer->pitchBend(tag, 64.0 + (f - pluckedFret) * 64 / 12);
	}
	fret = f;
	_pitchBend = 0;
}

- (void)pitchBend:(float)f {
	_pitchBend = f;
	if (tag >= 0) {
		voicer->pitchBend(tag, 64.0 + (fret + _pitchBend - pluckedFret) * 64 / 12);
	}
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
		float sample = ((VoicerManagingInstruments*)_voicer)->fastTick() * 0.5 * _volume;
//		float sample = _voicer->tick() * 2 * _volume;
		if (_effect) {
			sample = _effect->tick(sample);
		}
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

static float frequencyForString(int i) {
	return A_FREQ * pow(2.0, stringNotes[i] / 12);
}

- (id)initWithRect:(CGRect)rect {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	Stk::setSampleRate(SAMPLING_RATE);
	if ([defaults stringForKey:@"volume"]) {
		_volume = [defaults floatForKey:@"volume"];
	} else {
		_volume = 0.5;
	}
	_voicer = new VoicerManagingInstruments(1.0);
	_lock = [[NSLock alloc] init];
	_fretboard = [[Fretboard alloc] initWithRect:rect];
//	_effect = new PRCRev(0.5);
//	_effect = new Chorus();
	int i;
	for (i = 0; i < CHANNELS; i++) {
		_strings[i] = [[PluckedString alloc] initWithFrequency:frequencyForString(i) voicer:_voicer channel:i];
	}
	[self reloadSettings];
	return self;
}

/*
- (void)resetFrequencies {
	int i;
	for (i = 0; i < CHANNELS; i++) {
		[_strings[i] setFrequency:frequencyForString(_leftHanded ? CHANNELS - 1 - i : i)];
	}
}
*/

- (void)reloadInstruments {
	[_lock lock];
	printf("reload\n");
	((VoicerManagingInstruments*)_voicer)->clearInstruments();
	printf("cleared\n");
	int i;//, j;
	for (i = 0; i < CHANNELS; i++) {
		//for (j = 0; j < 2; j++) { // 2 instruments per channel
			Instrmnt *instr = [_instrument newInstrumentWithBaseFrequency:_strings[i]->frequency];
			_voicer->addInstrument(instr, i);
		//}
	}
	NSLog(@"reloadInstruments done");
	[_lock unlock];
}

- (void)setInstrument:(InstrumentFactory*)factory {
	if (_instrument && [[factory name] isEqualToString:[_instrument name]]) {
		return;
	}
	_instrument = factory;
	[self reloadInstruments];
}

- (void)saveSettings {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[_instrument name] forKey:@"instrumentName"];
	[defaults setInteger:_leftHanded forKey:@"leftHanded"];
	[_fretboard save];
}

- (void)saveVolume {
	[[NSUserDefaults standardUserDefaults] setFloat:_volume forKey:@"volume"];
}

- (void)reloadSettings {
	NSLog(@"reloadSettings");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *instrumentName = [defaults stringForKey:@"instrumentName"];
	InstrumentFactory *factory = NULL;
	if (instrumentName) {
		factory = [InstrumentFactory factoryWithName:instrumentName];
	}
	if (!factory) {
		factory = [InstrumentFactory defaultFactory];
	}
	_leftHanded = [defaults integerForKey:@"leftHanded"];
	[self setInstrument:factory];
	[_fretboard reload];
}


- (PluckedString*)stringAtIndex:(int)i {
	return _strings[_leftHanded ? CHANNELS - 1 - i : i];
}

- (float)volume {
	return _volume;
}

- (void)setVolume:(float)volume {
	_volume = volume;
}

- (Fretboard*)fretboard {
	return _fretboard;
}

- (InstrumentFactory*)instrument {
	return _instrument;
}

- (void)setLeftHanded:(BOOL)leftHanded {
	_leftHanded = leftHanded;
	//[self resetFrequencies];
}

- (BOOL)leftHanded {
	return _leftHanded;
}
@end
