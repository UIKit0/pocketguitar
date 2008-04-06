//
//  GuitarView.m
//
//  Created by shinya on 07/12/23.
//

#import "GuitarView.h"

#define DUMP_EVENTS 0
#define NUT_OFFSET 30

int GSEventGetEventNumber(GSEvent *ev);
CGPoint GSEventGetPathInfoAtIndex(GSEvent *ev, int i);
int GSEventGetHandInfo(GSEvent *ev);
id GSColorCreateColorWithDeviceRGBA(float f1, float f2, float f3, float f4);

struct GSPathPoint {
	char slot;
	char unk1;
	short int status;
	int unk2;
	float x;
	float y;
};

struct __GSEvent {
	int unk0;
	int unk1;
	int type;
	int subtype;
	float unk2;
	float unk3;
	float x;
	float y;
	int timestamp1;
	int timestamp2;
	int unk4;
	int modifierFlags;
	int unk5;
	int unk6;
	int mouseEvent;
	short int dx;
	short int fingerCount;
	int unk7;
	int unk8;
	char unk9;
	char numPoints;
	short int unk10;
	struct GSPathPoint points[10];
};


// --- PluckedString ---

@interface FingerImpl : Finger {
	BOOL pressed;
	BOOL plucked;
	CGPoint lastPluckPoint;
	PluckedString *string;
	CGPoint fretPoint;
	GuitarView *view;
	float fret;
}
-(float) fret;
@end


// --- Finger ---

@implementation FingerImpl
- (id)init:(GuitarView *)v {
	view = v;
	return self;
}

- (Fretboard*)fretboard {
	return [[view guitar] fretboard];
}

- (float)fretFromPoint:(float)y {
//	CGSize size = ((CGRect) [view bounds]).size;
//	float f = 12.0 / (1.0 - ((y - NUT_OFFSET) / size.height * SCALE_FACTOR)) - 12;
//	return ceil(f + 0.5);
	return ceil([[self fretboard] fretFromPosition:y]);
//	return ceil((y - NUT_OFFSET) / [board ]);
}

- (void)pressed:(CGPoint)point {
	pressed = TRUE;
	if (point.y < [[self fretboard] pickupOffset]) {
		fret = [self fretFromPoint:point.y];
		string = [view stringAt:point];
		[string addFinger:self];
		fretPoint = point;
	} else {
		PluckedString *str = [view stringAt:point];
		[str pluck];
		plucked = TRUE;
		lastPluckPoint = point;
	}
//	[view setNeedsDisplay];
}

- (void)dragged:(CGPoint)point {
	if (point.y < [[self fretboard] pickupOffset]) {
		float fretless = [[self fretboard] fretFromPosition:point.y];
		float newFret = ceil(fretless);
		if (string) {
			if (fret != newFret) {
				if ([string isLastFinger:self]) {
					[string setFret:newFret];
					fretPoint = point;
				}
			} else {
			/* TODO need more adjustments
				if ([string isLastFinger:self]) {
					float w = fretPoint.x - point.x;
					float h = fretPoint.y - point.y;
					float dist = sqrt(w * w + h * h) / 80;
					[string pitchBend:dist];
				}
			*/
			}
		}
		fret = newFret;
	} else {
		if (plucked) {
			int from = [view stringIndexAt:lastPluckPoint];
			int to = [view stringIndexAt:point];
			if (to != from) {
				int i;
				if (from > to) {
					int tmp = from;
					from = to;
					to = tmp;
				}
				for (i = from + 1; i <= to; i++) {
					[[view stringAtIndex:i] pluck];
				}
			}
		}
		lastPluckPoint = point;
	}
}

- (void)released {
	pressed = FALSE;
	if (string) {
		[string removeFinger:self];
	}
	plucked = FALSE;
	string = nil;
//	[view setNeedsDisplay];
}

- (BOOL)isPressed {
	return pressed;
}

- (float)fret {
	return fret;
}

@end

@interface FingerView : UIView {
}
@end

@implementation FingerView
- (void)drawRect:(CGRect)rect;
{
//	NSRect nsr;
	// = (NSRect)rect;
//	memcpy(&nsr, &rect, sizeof(NSRect));
//	[sketchView drawRect:nsr withContext:UICurrentContext()];
	CGContextRef context = UICurrentContext();
	CGContextClearRect(context, [self bounds]);
	CGContextSetLineWidth(context, 16);
	int i;
	
	GuitarView *view = (GuitarView*)[self superview];
	Fretboard *fretboard = [[view guitar] fretboard];
	for (i = 0; i < [fretboard stringCount]; i++) {
		float y = [fretboard fretPositionAt:(int)[[view stringAtIndex:i] fret]];
		float x = [fretboard stringPositionAt:i];
		CGContextSetRGBStrokeColor(context, 0, 1, 0, 1);
		CGContextMoveToPoint(context, x, [[[view guitar] fretboard] displayOffset]);
		CGContextAddLineToPoint(context, x, y);
		CGContextStrokePath(context);
	}
}

- (void)scanFingers:(GSEvent *)event {
	[(GuitarView*)[self superview] scanFingers:event];
}

- (void)dumpEvent:(GSEvent*)event {
#if DUMP_EVENTS
	NSLog(@"MouseEvent: %d, fingerCount: %hd, numPoints: %hhd, pos: %f, %f", event->mouseEvent, event->fingerCount, event->numPoints, event->x, event->y);
	int i;
	for (i = 0; i < event->numPoints; i++) {
		NSLog(@"  Point %d: %f, %f %d %d %d %d", i + 1, event->points[i].x, event->points[i].y, 
				(int)event->points[i].status,
				(int)event->points[i].slot,
				(int)event->points[i].unk1,
				(int)event->points[i].unk2
				);
	}
#endif
}

- (void)gestureStarted:(GSEvent *)event {
	[self dumpEvent:event];
	[self scanFingers:event];
}

- (void)gestureChanged:(GSEvent *)event {
	[self dumpEvent:event];
	[self scanFingers:event];
}

- (void)gestureEnded:(GSEvent *)event {
	[self dumpEvent:event];
	[self scanFingers:event];
}

- (void)mouseDown:(GSEvent *)event {
	[self dumpEvent:event];
	[self scanFingers:event];
}

- (void)mouseDragged:(GSEvent *)event {
	[self dumpEvent:event];
	[self scanFingers:event];
}

- (void)mouseUp:(GSEvent *)event {
	[self dumpEvent:event];
	[self scanFingers:event];
}

@end

@implementation GuitarView

- (void)drawRect:(CGRect)rect;
{
//	NSRect nsr;
	// = (NSRect)rect;
//	memcpy(&nsr, &rect, sizeof(NSRect));
//	[sketchView drawRect:nsr withContext:UICurrentContext()];
//	CGContextRef context = UICurrentContext();
//	CGContextClearRect(context, [self bounds]);
//	[[[self guitar] fretboard] drawRect:rect withContext:context andEnableDrag:NO];
}

- (void)updateView {
//	[self setNeedsDisplay];
}

- (void)setVolume:(float)v {
	[_guitar setVolume:v];
}

- (id)initWithFrame:(CGRect)rect {
    self = [super initWithFrame:rect];
	int i;
	_guitar = [[Guitar alloc] initWithRect:rect];
	for (i = 0; i < FINGER_SLOTS; i++) {
		fingers[i] = [[FingerImpl alloc] init:self];
	}
	[_guitar start];
	
	_fretboardView = [[FretboardView alloc] initWithFrame:rect];
	[_fretboardView setFretboard:[_guitar fretboard]];
	[self addSubview:_fretboardView];
	
    UIView *fingerView = [[FingerView alloc] initWithFrame:rect];
	[fingerView setOpaque:FALSE];
    [self addSubview:fingerView];
	
	[NSTimer scheduledTimerWithTimeInterval:0.2
		 target:fingerView
		 selector:@selector(setNeedsDisplay) 
		 userInfo:nil 
		 repeats:YES];
	[fingerView setEnabledGestures: TRUE];

//	sliderView = [[VolumeSliderView alloc] initWithFrame:CGRectMake(100, 0, rect.size.width - 100, NUT_OFFSET - 3) andVolume:[_guitar volume]];
	sliderView = [[UISliderControl alloc] initWithFrame:CGRectMake(120, 0, rect.size.width - 140, NUT_OFFSET - 3)];
    [sliderView setBackgroundColor:(CGColorRef)[(id)GSColorCreateColorWithDeviceRGBA(0.0f, 0.0f, 0.0f, 0.0f) autorelease]];
//	volume = vol;
	NSLog(@"init1.5");
	[sliderView setMinValue:0.0];
	[sliderView setMaxValue:1.0];
	[sliderView setValue: [_guitar volume]];
	[sliderView addTarget:self action:@selector(volumeUpdated) forEvents:1|4]; // mouseDown | mouseDragged
//	[sliderView setVolumeListener:self];
	[self addSubview:sliderView];

	return self;
}

- (void)volumeUpdated {
	[self setVolume:[sliderView value]];
}

- (void)scanFingers:(GSEvent *)event {
	int i;
	BOOL pressedList[FINGER_SLOTS];
	struct GSPathPoint *points[FINGER_SLOTS];
	
	memset(pressedList, 0, sizeof(pressedList));
	memset(points, 0, sizeof(points));
	for (i = 0; i < event->numPoints; i++) {
		struct GSPathPoint *point = &event->points[i];
		int slot = (int)point->slot;
		points[slot] = point;
		pressedList[slot] = (int)point->status & 2;
	}
	
	for (i = 0; i < FINGER_SLOTS; i++) {
		struct GSPathPoint *point = points[i];
		BOOL pressed = pressedList[i];
		CGPoint p;
		if (point) {
			p.x = point->x;
			p.y = point->y;
		}
		FingerImpl *finger = (FingerImpl*)fingers[i];
		if ([finger isPressed] && !pressed) {
			if (point) {
//				printf("released %d: %f, %f\n", (int)point->slot, point->x, point->y);
				[finger dragged:p];
			}
			[finger released];
			//fingers[point->slot].pressed = FALSE;
		} else if (![finger isPressed] && pressed) {
//			printf("pressed %d: %f, %f\n", (int)point->slot, point->x, point->y);
			[finger pressed:p];
			//fingers[point->slot].pressed = TRUE;
		} else if (pressed && [finger isPressed]) {
			[finger dragged:p];
		}
	}
}

- (PluckedString*)stringAtIndex:(int)index {
	return [_guitar stringAtIndex:index];
}

- (PluckedString*)stringAt:(CGPoint)point {
	return [_guitar stringAtIndex:[self stringIndexAt:point]];
}

- (int)stringIndexAt:(CGPoint)point {
	return [[[self guitar] fretboard] stringIndexFromPosition:point.x];
}

- (float)fretPositionAt:(int)index {
	return [[[self guitar] fretboard] fretPositionAt:index];
}

- (Guitar*)guitar {
	return _guitar;
}
@end
