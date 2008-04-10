//
//  Fretboard.m
//  PocketGuitar
//
//  Created by shinya on 08/01/22.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Fretboard.h"

#define DEBUG_GRID 0

@implementation Fretboard

- (id)initWithRect:(CGRect)rect {
	_rect = rect;

	[self loadDefault];
	[self reload];
	return self;
}

- (void)loadDefault {
	_fretCount = 6;
	_stringCount = 6;
	_distanceBetweenFrets = 64;
	_stringMargin = -2;
	_displayHeight = 320;
	_displayOffset = 43;
	_leftHanded = NO;
}

- (int)fretCount {
	return _fretCount;
}

- (int)stringCount {
	return _stringCount;
}

- (float)fretPositionAt:(int)fret {
	return _displayOffset + _distanceBetweenFrets * fret;
}

- (float)stringPositionAt:(int)string {
	return ((float)string + 0.5) / _stringCount * (_rect.size.width - _stringMargin * 2) + _stringMargin;
}

- (float)fretFromPosition:(float)position {
	return (position - _displayOffset) / _distanceBetweenFrets;
}

- (float)stringFromPosition:(float)position {
	return (position - _stringMargin) / (_rect.size.width - _stringMargin * 2) * _stringCount;
}

- (int)stringIndexFromPosition:(float)position {
	int index = (int)floorf([self stringFromPosition:position]);
	if (index < 0) index = 0;
	if (index >= _stringCount) index = _stringCount - 1;
	return index;
}

- (float)stringMargin {
	return _stringMargin;
}

- (float)displayHeight {
	return _displayHeight;
}

- (void)setStringMargin:(float)margin {
	_stringMargin = margin;
}

- (void)setDistanceBetweenFrets:(float)distance {
	_distanceBetweenFrets = distance;
}

- (void)setDisplayHeight:(float)height {
	_displayHeight = height;
}

- (void)save {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setFloat:_distanceBetweenFrets forKey:@"distanceBetweenFrets"];
	[defaults setFloat:_displayHeight forKey:@"displayHeight"];
	[defaults setFloat:_stringMargin forKey:@"stringMargin"];
}

- (void)reload {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults stringForKey:@"distanceBetweenFrets"]) {
		_distanceBetweenFrets = [defaults floatForKey:@"distanceBetweenFrets"];
	}
	if ([defaults stringForKey:@"displayHeight"]) {
		_displayHeight = [defaults floatForKey:@"displayHeight"];
	}
	if ([defaults stringForKey:@"stringMargin"]) {
		_stringMargin = [defaults floatForKey:@"stringMargin"];
	}
	_leftHanded = [defaults integerForKey:@"leftHanded"];
	NSLog(@"distance=%f", _distanceBetweenFrets);
}

- (BOOL)leftHanded {
	return _leftHanded;
}

- (float)pickupOffset {
	return _displayOffset + _displayHeight;
}

- (float)displayOffset {
	return _displayOffset;
}

- (CGSize)size {
	return _rect.size;
}

- (float)distanceBetweenFrets {
	return _distanceBetweenFrets;
}

@end
