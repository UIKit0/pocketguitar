//
//  InstrumentFactory.mm
//
//  Created by shinya on 08/01/06.
//

#include <Voicer.h>
#include <Plucked.h>
#include <Mandolin.h>
#include <Rhodey.h>
#include <Moog.h>
#include <Simple.h>
#include <Sitar.h>
#include <Chorus.h>
#include <PRCRev.h>
#include <NRev.h>
#include <JCRev.h>
#include <sys/types.h>
#include <sys/stat.h>

#import "AudioOutput.h"
#import "InstrumentFactory.h"

@interface Sample : NSObject {
	@public NSString *filename;
	@public float frequency;
	@public float amplitude;
}
@end

@implementation Sample
@end

@interface WaveData : NSObject {
	@public int _size;
	@public short *_buffer;
	int _refCount;
	NSMutableDictionary *_cache;
	NSString *_filename;
}
@end

@implementation WaveData
- (id)initWithFile:(NSString*)filenameString cache:(NSMutableDictionary*)cache {
	const char *filename = [filenameString UTF8String];
	struct stat filestat;
	if (stat(filename, &filestat) == -1) {
		[NSException raise:@"WaveDataError" format:@"failed to stat file"];
	}
	_buffer = (short*)malloc(filestat.st_size);
	_size = filestat.st_size / sizeof(short);
	
	int fd = open(filename, O_RDONLY, 0);
	if (fd < 0) {
		[NSException raise:@"WaveDataError" format:@"failed to open file"];
	}
	
	int rest = filestat.st_size;
	char *cbuf = (char *)_buffer;
	while (rest > 0) {
		int r = read(fd, cbuf, rest);
		if (r < 0) {
			[NSException raise:@"WaveDataError" format:@"failed to read file"];
		}
		rest -= r;
		cbuf += r;
	}
	close(fd);

	_filename = filenameString;
	_cache = cache;
	[cache setObject:self forKey:filenameString];
	
	return self;
}

+ (id)loadFromFile:(NSString*)file withCache:(NSMutableDictionary*)cache {
	WaveData *data = [cache objectForKey:file];
	if (!data) {
		data = [[WaveData alloc] initWithFile:file cache:cache];
	}
	return data;
}

- (void)incrementRefCount {
	_refCount++;
}

- (void)decrementRefCount {
	_refCount--;
	if (_refCount == 0) {
		[self release];
		if ([self retainCount] == 1) { // It is now only referenced from cache
			NSLog(@"Destroying data from %@", _filename);
			[_cache removeObjectForKey:_filename];
		}
	}
}

- (void)dealloc {
	free(_buffer);
	[super dealloc];
}
@end

class SimpleSampler : public Instrmnt {
	float _base;
	WaveData *_data;
	float _time;
	BOOL _keyOn;
	float _rate;
	float _envelope;
	float _releaseRate;
	float _releaseOutput;
	float _amplitude;
public:
	SimpleSampler(WaveData *data, float base, float amplitude);
	~SimpleSampler();
	void noteOn(StkFloat frequency, StkFloat amplitude);
	void noteOff(StkFloat amplitude);
	void setFrequency(StkFloat frequency);
	void controlChange(int number, StkFloat value);
protected:
	StkFloat computeSample( void );
	short valueAt(int i);
};

SimpleSampler::SimpleSampler(WaveData *data, float base, float amplitude) {
	_data = data;
	_rate = 1.0;
	_releaseRate = 1.0 / SAMPLING_RATE / 0.5; // 0.5 sec
	_base = base;
	_releaseOutput = 0;
	_keyOn = NO;
	_amplitude = amplitude;
	[_data incrementRefCount];
}

SimpleSampler::~SimpleSampler() {
	NSLog(@"destroying SimpleSampler");
	[_data decrementRefCount];
}

void SimpleSampler :: controlChange(int number, StkFloat value) {
}

void SimpleSampler::setFrequency(StkFloat frequency) {
	_rate = frequency / _base;
}

void SimpleSampler :: noteOn(StkFloat frequency, StkFloat amplitude) {
	this->setFrequency(frequency);
	if (_keyOn) {
		_releaseOutput = lastOutput_;
	}
	_keyOn = YES;
	_time = 0;
	_envelope = _amplitude;
}

void SimpleSampler :: noteOff(StkFloat amplitude) {
	_keyOn = NO;
	_releaseOutput = lastOutput_;
	_envelope = 0;
}

short SimpleSampler::valueAt(int i) {
	if (i < _data->_size) {
		return _data->_buffer[i];
	} else {
		return 0;
	}
}

StkFloat SimpleSampler :: computeSample()
{
	float value = 0;
	if (_keyOn || _envelope > 0) {
		float ft;
		if (_rate == 1.0f) {
			ft = _time;
		} else {
			ft = floorf(_time);
		}
		int it = (int) ft;
		if ((it + 1) >= _data->_size) { // end of data
			_keyOn = NO;
			_envelope = 0;
		} else {
			float d = _time - ft;
			if (d > 0) {
//				int r = (int)((1.0 - (_time - ft)) * 0x10000);
//				float r = 1.0 - (_time - ft)
				value = _envelope * (_data->_buffer[it] * (1.0f - d) + _data->_buffer[it + 1] * d) / 32768;
			} else {
				value = (float) _data->_buffer[it] / 32768;
			}
			_time += _rate;
			if (!_keyOn) {
				_envelope -= _releaseRate;
				if (_envelope < 0) _envelope = 0;
			}
		}
	}
	if (_releaseOutput != 0) {
		value += _releaseOutput;
		if (_releaseOutput > 0) {
			_releaseOutput -= 0.001f;
			if (_releaseOutput < 0) _releaseOutput = 0;
		} else {
			_releaseOutput += 0.001f;
			if (_releaseOutput > 0) _releaseOutput = 0;
		}
	}
	lastOutput_ = value;
	return value;
}

static float stringNotes[] = {-5, 0, 5, 10, 14, 19};
static NSString *fileNames[] = {@"e6", @"a5", @"d4", @"g3", @"b2", @"e1"};
#define A_FREQ 110

@interface SampledGuitarFactory : InstrumentFactory {
	NSString *_name;
	NSString *_directory;
	NSMutableDictionary *_dataCache;
	NSArray *_samples;
}
@end

@implementation SampledGuitarFactory
- (Instrmnt *)newInstrumentWithBaseFrequency:(float)freq {
	NSEnumerator *enm = [_samples objectEnumerator];
	Sample *sample;
	while ((sample = [enm nextObject])) {
		if (sample->frequency >= freq) {
			break;
		}
	}
	if (!sample) sample = [_samples lastObject];
	NSString *file = [[NSString alloc] initWithFormat:@"/var/root/Media/PocketGuitar/%@/%@.raw", _directory, sample->filename];
	NSLog(@"SampledGuitarFactory: newInstrument: %@ %f", sample->filename, sample->frequency);
	WaveData *data = [_dataCache objectForKey:file];
	if (!data) {
		NSLog(@"SampledGuitarFactory: loading from %@", file);
		data = [WaveData loadFromFile:file withCache:_dataCache];
	}
	return new SimpleSampler(data, sample->frequency, sample->amplitude);
}

- (NSString *)name {
	return _name;
}

- (id)initWithName:(NSString*)name directory:(NSString*)directory samples:(NSArray*)samples {
	self = [super init];
	_name = name;
	_directory = directory;
	_samples = samples;
	_dataCache = [[NSMutableDictionary alloc] initWithCapacity:10];
	return self;
}
@end


@interface PluckedFactory : InstrumentFactory
@end

@implementation PluckedFactory
- (Instrmnt *)newInstrumentWithBaseFrequency:(float)freq {
	return new Plucked(freq);
}

- (NSString *)name {
	return @"Plucked";
}
@end

@interface MandolinFactory : InstrumentFactory
@end

@implementation MandolinFactory
- (Instrmnt *)newInstrumentWithBaseFrequency:(float)freq {
	return new Mandolin(freq);
}

- (NSString *)name {
	return @"Mandolin";
}
@end

@interface RhodeyFactory : InstrumentFactory
@end

@implementation RhodeyFactory
- (Instrmnt *)newInstrumentWithBaseFrequency:(float)freq {
	return new Rhodey();
}

- (NSString *)name {
	return @"Rhodey";
}
@end

@interface MoogFactory : InstrumentFactory
@end

@implementation MoogFactory
- (Instrmnt *)newInstrumentWithBaseFrequency:(float)freq {
	return new Moog();
}

- (NSString *)name {
	return @"Moog";
}
@end

@interface SimpleFactory : InstrumentFactory
@end

@implementation SimpleFactory
- (Instrmnt *)newInstrumentWithBaseFrequency:(float)freq {
	return new Simple();
}

- (NSString *)name {
	return @"Simple";
}
@end

@interface SitarFactory : InstrumentFactory
@end

@implementation SitarFactory
- (Instrmnt *)newInstrumentWithBaseFrequency:(float)freq {
	return new Sitar(freq);
}

- (NSString *)name {
	return @"Sitar";
}
@end

@implementation InstrumentFactory

static NSMutableArray *allInstruments;

+ (id)defaultFactory {
	return [[self allInstruments] objectAtIndex:0];
}

+ (id)factoryWithName:(NSString*)name {
	NSEnumerator *instruments = [[self allInstruments] objectEnumerator];
	InstrumentFactory *factory;
	while ((factory = [instruments nextObject])) {
		if ([[factory name] isEqualToString:name]) {
			return factory;
		}
	}
	return NULL;
}

+ (NSArray *)allInstruments {
	if (!allInstruments) {
		int i;
		NSMutableArray *guitar, *bass;
		guitar = [[NSMutableArray alloc] initWithCapacity:10];
			NSLog(@"aaaa");
		for (i = 0; i < 6; i++) {
			Sample *item = [[Sample alloc] init];
			NSLog(@"aaa");
			item->filename = fileNames[i];
			item->frequency = A_FREQ * pow(2.0, stringNotes[i] / 12);
			item->amplitude = 0.8;
			[guitar addObject:item];
		}
		bass = [[NSMutableArray alloc] initWithCapacity:10];
		for (i = 0; i < 4; i++) {
			Sample *item = [[Sample alloc] init];
			item->filename = fileNames[i];
			item->frequency = A_FREQ * pow(2.0, stringNotes[i] / 12);
			item->amplitude = 1.0;
			[bass addObject:item];
		}
		/*
		((Sample*)[bass objectAtIndex:0])->amplitude = 1.7;
		((Sample*)[bass objectAtIndex:1])->amplitude = 1.5;
		((Sample*)[bass objectAtIndex:2])->amplitude = 1.3;
		((Sample*)[bass objectAtIndex:3])->amplitude = 1.1;
		*/
		NSLog(@"ffo");
		allInstruments = [[NSMutableArray alloc] initWithCapacity:10];
		[allInstruments addObject:[[SampledGuitarFactory alloc] initWithName:@"Distorted Guitar" directory:@"DistortedGuitar" samples:guitar]];
		[allInstruments addObject:[[SampledGuitarFactory alloc] initWithName:@"Acoustic-Electric Guitar" directory:@"AcousticElectricGuitar" samples:guitar]];
		[allInstruments addObject:[[SampledGuitarFactory alloc] initWithName:@"Electric Bass" directory:@"ElectricBass" samples:bass]];
//		[allInstruments addObject:[[PluckedFactory alloc] init]];
//		[allInstruments addObject:[[MandolinFactory alloc] init]];
//		[allInstruments addObject:[[RhodeyFactory alloc] init]];
//		[allInstruments addObject:[[MoogFactory alloc] init]];
//		[allInstruments addObject:[[SimpleFactory alloc] init]];
//		[allInstruments addObject:[[SitarFactory alloc] init]];
	}
	return allInstruments;
}

@end
