//
//  Fretboard.m
//  PocketGuitar
//
//  Created by shinya on 08/01/22.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Fretboard.h"


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
	_distanceBetweenFrets = 56;
	_stringMargin = -16;
	_displayHeight = 320;
	_displayOffset = 30;
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
	NSLog(@"distance=%f", _distanceBetweenFrets);
}

static void drawLine(CGContextRef context, float x1, float y1, float x2, float y2) {
	CGContextMoveToPoint(context, x1, y1);
	CGContextAddLineToPoint(context, x2, y2);
	CGContextStrokePath(context);
}

- (void)drawRect:(CGRect)rect withContext:(CGContextRef)context andEnableDrag:(BOOL)drag {
	CGSize size = rect.size;
	CGContextSetRGBFillColor(context, 0.17, 0.04, 0.01, 1);
	CGContextFillRect(context, CGRectMake(0, _displayOffset, rect.size.width, _displayHeight));
	
	int i;
	float y;
	
	for (i = 0; i <= 100; i++) {
		y = [self fretPositionAt:i];
		if (y >= _displayHeight + _displayOffset) {
			break;
		}
		CGContextSetLineWidth(context, 3);
		if (drag && i == DRAG_FRET)  {
			CGContextSetRGBStrokeColor(context, 1.0, 0.5, 0.5, 1);
		} else {
			CGContextSetRGBStrokeColor(context, 0.6, 0.6, 0.6, 1);
		}
		drawLine(context, 0, y - 1, size.width, y - 1);
		
		CGContextSetLineWidth(context, 1);
		CGContextSetRGBStrokeColor(context, 0.2, 0.2, 0.2, 1);
		drawLine(context, 0, y + 1, size.width, y + 1);
	}

	for (i = 0; i < _stringCount; i++) {
		float x = ((float)i + 0.5) / _stringCount * (size.width - _stringMargin * 2) + _stringMargin;
		
		CGContextSetLineWidth(context, 4);
		if (drag && i == _stringCount - 1) {
			CGContextSetRGBStrokeColor(context, 1, 1, 0.1, 1);
		} else {
			CGContextSetRGBStrokeColor(context, 1, 1, 1, 1);
		}
		drawLine(context, x, _displayOffset, x, size.height);

		CGContextSetLineWidth(context, 1);
		CGContextSetRGBStrokeColor(context, 0.3, 0.3, 0.3, 1);
		drawLine(context, x + 2, _displayOffset, x + 2, size.height);
	}
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

@end
