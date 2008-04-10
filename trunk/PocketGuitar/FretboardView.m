//
//  FretboardView.m
//  PocketGuitar
//
//  Created by shinya on 08/04/02.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "FretboardView.h"

id GSColorCreateColorWithDeviceRGBA(float f1, float f2, float f3, float f4);

@interface FretboardShadingView: UIView {
	CGFunctionRef _shadingFunction;
}
@end

@implementation FretboardShadingView

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

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UICurrentContext();
	
	CGPoint shadingStartPoint = {0, 0};
	CGPoint shadingEndPoint = {0, 20};
    CGShadingRef shading = CGShadingCreateAxial(CGColorSpaceCreateDeviceRGB(), shadingStartPoint, shadingEndPoint, 
												_shadingFunction, NO, NO);
	CGContextDrawShading(context, shading);
	CGShadingRelease(shading);

	CGContextSetRGBFillColor(context, 0, 0, 0, 1);
	CGContextFillRect(context, CGRectMake(0, 20, rect.size.width, rect.size.height - 20));
}

- (id)initWithFrame:(CGRect)rect {
	self = [super initWithFrame:rect];
	_shadingFunction = createShadingFunction();
	return self;
}

@end

@implementation FretboardView

- (void)setFretboard:(Fretboard*)fretboard {
	_fretboard = fretboard;
	[self reloadFretboard];
}

const int dotFrets[] = {3, 5, 7, 9};

- (void)reloadFretboard {
	int i;
	for (i = 0; i < VIEW_MAX_FRETS; i++) {
		int y = [_fretboard fretPositionAt:i];
		[_fretViews[i] setFrame:CGRectMake(0, y - 25, 320, 48)];
	}

	for (i = 0; i < VIEW_MAX_DOTS; i++) {
		int y = [_fretboard fretPositionAt:dotFrets[i]];
		[_dotViews[i] setFrame:CGRectMake(320 / 2 - 10, y - [_fretboard distanceBetweenFrets] / 2 - 14, 23, 24)];
	}
	
	[_shadingView setFrame:CGRectMake(0, [_fretboard pickupOffset], 320, 200)];
	
	for (i = 0; i < [_fretboard stringCount]; i++) {
		float x = ((float)i + 0.5) / [_fretboard stringCount] * (320 - [_fretboard stringMargin] * 2) + [_fretboard stringMargin];
		int stringIndex = i;
		if ([_fretboard leftHanded]) {
			stringIndex = STRING_IMAGES - stringIndex - 1;
		}
		[_stringViews[stringIndex] setFrame:CGRectMake(x - 2, 0, 10, 480)];
	}
}

/*
- (void)drawRect:(CGRect)rect {
	CGContextRef context = UICurrentContext();
	[_fretboard drawRect:rect withContext:context andEnableDrag:NO];
}
*/

static NSString *stringImageFiles[] = {
	@"e6.png",
	@"a5.png",
	@"d4.png",
	@"g3.png",
	@"b2.png",
	@"e1.png"
};

- (id)initWithFrame:(CGRect)rect {
    self = [super initWithFrame:rect];
	
	_backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, -30, 320, 480)];
	_backgroundView.image = [UIImage imageNamed:@"fretboard.png"];
	[self addSubview:_backgroundView];
	
	UIImage *fretImage = [UIImage imageNamed:@"fret.png"];
	int i;
	for (i = 0; i < VIEW_MAX_FRETS; i++) {
		UIImageView *fretView = [[UIImageView alloc] initWithImage:fretImage];
		[self addSubview:fretView];
		_fretViews[i] = fretView;
	}
	
	UIImage *dotImage = [UIImage imageNamed:@"dot.png"];
	for (i = 0; i < VIEW_MAX_DOTS; i++) {
		UIImageView *dotView = [[UIImageView alloc] initWithImage:dotImage];
		[self addSubview:dotView];
		_dotViews[i] = dotView;
	}
	
	_shadingView = [[FretboardShadingView alloc] initWithFrame:rect];
	[_shadingView setBackgroundColor:(CGColorRef)[(id)GSColorCreateColorWithDeviceRGBA(0.0f, 0.0f, 0.0f, 0.0f) autorelease]];
	[self addSubview:_shadingView];
	
	for (i = 0; i < STRING_IMAGES; i++) {
		UIImage *stringImage = [UIImage imageNamed:stringImageFiles[i]];
		UIImageView *stringView = [[UIImageView alloc] initWithImage: stringImage];
		[self addSubview:stringView];
		_stringViews[i] = stringView;
	}

	return self;
}

@end
