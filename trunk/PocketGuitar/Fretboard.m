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

static NSString *stringImageFiles[] = {
	@"e6",
	@"a5",
	@"d4",
	@"g3",
	@"b2",
	@"e1"
};

static void evaluateGradient(void *info, const float *in, float *out)
{
	out[0] = 0;
	out[1] = 0;
	out[2] = 0;
	out[3] = (cos((1.0 - in[0]) * M_PI) + 1) / 2;
}

static CGFunctionRef createShadingFunction() {
	float domain[] = {0, 1};
	float range[] = {0, 1, 0, 1, 0, 1, 0, 1};
    CGFunctionCallbacks shadingCallbacks;
	
    shadingCallbacks.version = 0;
    shadingCallbacks.evaluate = &evaluateGradient;
    shadingCallbacks.releaseInfo = NULL;
	
	return CGFunctionCreate(NULL, 1, domain, 4, range, &shadingCallbacks);
}

- (id)initWithRect:(CGRect)rect {
	int i;
	_rect = rect;

	CGImageSourceRef source;
	source = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"fretboard" ofType:@"png"]], NULL);
	_fretboardImage = CGImageSourceCreateImageAtIndex(source, 0, NULL);
	source = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"fret" ofType:@"png"]], NULL);
	_fretImage = CGImageSourceCreateImageAtIndex(source, 0, NULL);
	source = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"dot" ofType:@"png"]], NULL);
	_dotImage = CGImageSourceCreateImageAtIndex(source, 0, NULL);
	
	for (i = 0; i < STRING_IMAGES; i++) {
		source = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:stringImageFiles[i] ofType:@"png"]], NULL);
		_stringImages[i] = CGImageSourceCreateImageAtIndex(source, 0, NULL);
	}
	
	_shadingFunction = createShadingFunction();
	
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

#define Y(y) (-(y))

- (void)drawRect:(CGRect)rect withContext:(CGContextRef)context andEnableDrag:(BOOL)drag {
	CGSize size = rect.size;
//	CGContextSetRGBFillColor(context, 0.17, 0.04, 0.01, 1);
//	CGContextFillRect(context, CGRectMake(0, _displayOffset, rect.size.width, _displayHeight));
	NSLog(@"w=%f", rect.size.width);
	NSLog(@"h=%f", rect.size.height);

	// The image is drawn upside down with the the default scale,
	// so we'll flip the context
	CGContextScaleCTM(context, 1.0, Y(1.0));
	CGContextSaveGState(context);
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, CGRectMake(0, Y(0), 320, Y([self pickupOffset] + 20)));
	CGContextAddPath(context, path);
	CGContextClip(context);
	

	CGContextDrawImage(context, CGRectMake(0, Y(-30), 320, Y(480)), _fretboardImage);

	CGPoint shadingStartPoint = {0, Y([self pickupOffset])};
	CGPoint shadingEndPoint = {0, Y([self pickupOffset] + 20)};
    CGShadingRef shading = CGShadingCreateAxial(CGColorSpaceCreateDeviceRGB(), shadingStartPoint, shadingEndPoint, 
												_shadingFunction, NO, NO);
	CGContextDrawShading(context, shading);

	CGShadingRelease(shading);
	CGContextRestoreGState(context);
	CGPathRelease(path);

	int i;
	float y;
	
	for (i = 0; i <= 100; i++) {
		y = [self fretPositionAt:i];
		if (y >= _displayHeight + _displayOffset) {
			break;
		}
#if DEBUG_GRID
		CGContextSetLineWidth(context, 3);
		if (drag && i == DRAG_FRET)  {
			CGContextSetRGBStrokeColor(context, 1.0, 0.5, 0.5, 1);
		} else {
			CGContextSetRGBStrokeColor(context, 0.6, 0.6, 0.6, 1);
		}
		drawLine(context, 0, Y(y - 1), size.width, Y(y - 1));
#endif
		
//		CGContextSetLineWidth(context, 1);
//		CGContextSetRGBStrokeColor(context, 0.2, 0.2, 0.2, 1);
//		drawLine(context, 0, y + 1, size.width, y + 1);

		if (3 == i || 5 == i || 7 == i || 9 == i) {
			CGContextDrawImage(context, CGRectMake(320 / 2 - 10, Y(y - _distanceBetweenFrets / 2 - 14), 23, Y(24)), _dotImage);
		}
		
		if (i > 0) {
//		CGContextScaleCTM(context, 1.0, -1.0);
		CGContextDrawImage(context, CGRectMake(0, Y(y - 25), 320, Y(48)), _fretImage);
//		CGContextScaleCTM(context, 1.0, -1.0);
		}
	}

	for (i = 0; i < _stringCount; i++) {
		float x = ((float)i + 0.5) / _stringCount * (size.width - _stringMargin * 2) + _stringMargin;
		
#if DEBUG_GRID
		CGContextSetLineWidth(context, 4);
		if (drag && i == _stringCount - 1) {
			CGContextSetRGBStrokeColor(context, 1, 1, 0.1, 1);
		} else {
			CGContextSetRGBStrokeColor(context, 1, 1, 1, 1);
		}
//		drawLine(context, x, Y(_displayOffset), x, Y(size.height));

		CGContextSetLineWidth(context, 1);
		CGContextSetRGBStrokeColor(context, 0.3, 0.3, 0.3, 1);
//		drawLine(context, x + 2, Y(_displayOffset), x + 2, Y(size.height));

#endif
		CGContextDrawImage(context, CGRectMake(x - 2, Y(0), 10, Y(size.height)), _stringImages[i]);
	}
	CGContextScaleCTM(context, 1.0, Y(1.0));
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
