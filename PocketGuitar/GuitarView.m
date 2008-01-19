//
//  GuitarView.m
//
//  Created by shinya on 07/12/23.
//

#import "GuitarView.h"

#define SCALE_FACTOR 0.4
#define NUT_OFFSET 30
#define DUMP_EVENTS 0
#define FRET_SIZE 56
#define PICKUP_OFFSET 350
#define FRET_MARGIN -16

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

//static float strings[STRINGS];

@interface VolumeSliderView : UIView {
	float volume;
	id delegate;
}
@end

@implementation VolumeSliderView
- (id)initWithFrame:(CGRect)rect {
    [super initWithFrame:rect];
    [self setBackgroundColor:(CGColorRef)[(id)GSColorCreateColorWithDeviceRGBA(1.0f, 0.8f, 0.2f, 0.5f) autorelease]];
	volume = 0.8;
	return self;
}

- (void)setDelegate:(id)d {
	delegate = d;
}

- (void)drawRect:(CGRect)rect;
{
	CGContextRef context = UICurrentContext();
	CGContextClearRect(context, rect);
	CGContextSetRGBFillColor(context, 1.0, 1.0, 0, 1.0);
	CGContextFillRect(context, CGRectMake(0, 0, volume * rect.size.width, rect.size.height));
}

- (void)mouseDragged:(GSEvent *)event {
	CGPoint point = GSEventGetLocationInWindow(event);
	CGRect frame = [self frame];
	volume = (point.x - frame.origin.x) / frame.size.width;
	if (volume < 0) volume = 0;
	if (volume > 1) volume = 1;
	[delegate setVolume:volume];
	[self setNeedsDisplay];
}

@end

// --- PluckedString ---

@interface FingerImpl : Finger {
	BOOL pressed;
	BOOL plucked;
	CGPoint lastPluckPoint;
	PluckedString *string;
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

- (float)fretFromPoint:(float)y {
//	CGSize size = ((CGRect) [view bounds]).size;
//	float f = 12.0 / (1.0 - ((y - NUT_OFFSET) / size.height * SCALE_FACTOR)) - 12;
//	return ceil(f + 0.5);
	return ceil((y - NUT_OFFSET) / FRET_SIZE);
}

- (void)pressed:(CGPoint)point {
	pressed = TRUE;
	if (point.y < PICKUP_OFFSET) {
		fret = [self fretFromPoint:point.y];
		string = [view stringAt:point];
		[string addFinger:self];
	} else {
		PluckedString *str = [view stringAt:point];
		[str pluck];
		plucked = TRUE;
		lastPluckPoint = point;
	}
//	[view setNeedsDisplay];
}

- (void)dragged:(CGPoint)point {
	if (point.y < PICKUP_OFFSET) {
		float newFret = [self fretFromPoint:point.y];
		if (string && fret != newFret) {
			if ([string isLastFinger:self]) {
				[string setFret:newFret];
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
	CGSize size = ((CGRect) [self bounds]).size;
	CGContextSetLineWidth(context, 16);
	int i;
	
	GuitarView *view = (GuitarView*)[self superview];
	for (i = 0; i < STRINGS; i++) {
		float y = [view fretPositionAt:(int)[[view stringAtIndex:i] fret]];
		float x = ((float)i + 0.5) / STRINGS * (size.width - FRET_MARGIN * 2) + FRET_MARGIN;
		CGContextSetRGBStrokeColor(context, 0, 1, 0, 1);
		CGContextMoveToPoint(context, x, NUT_OFFSET);
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
	CGContextRef context = UICurrentContext();
	CGContextClearRect(context, [self bounds]);
	CGSize size = ((CGRect) [self bounds]).size;
	
	CGContextSetRGBFillColor(context, 0.17, 0.04, 0.01, 1);
	CGContextFillRect(context, CGRectMake(0, NUT_OFFSET, rect.size.width, PICKUP_OFFSET));

	int i;
	
	for (i = 0; i < MAX_FRETS; i++) {
		float y = fretPositions[i];
		
		CGContextSetLineWidth(context, 3);
		CGContextSetRGBStrokeColor(context, 0.6, 0.6, 0.6, 1);
		CGContextMoveToPoint(context, 0, y - 1);
		CGContextAddLineToPoint(context, size.width, y - 1);
		CGContextStrokePath(context);
		
		CGContextSetLineWidth(context, 1);
		CGContextSetRGBStrokeColor(context, 0.2, 0.2, 0.2, 1);
		CGContextMoveToPoint(context, 0, y + 2);
		CGContextAddLineToPoint(context, size.width, y + 2);
		CGContextStrokePath(context);
	}
	
	for (i = 0; i < STRINGS; i++) {
		
		float x = ((float)i + 0.5) / STRINGS * (size.width - FRET_MARGIN * 2) + FRET_MARGIN;

		CGContextSetLineWidth(context, 4);
		CGContextSetRGBStrokeColor(context, 1, 1, 1, 1);
		CGContextMoveToPoint(context, x, NUT_OFFSET);
		CGContextAddLineToPoint(context, x, size.height);
		CGContextStrokePath(context);

		CGContextSetLineWidth(context, 1);
		CGContextSetRGBStrokeColor(context, 0.3, 0.3, 0.3, 1);
		CGContextMoveToPoint(context, x + 3, NUT_OFFSET);
		CGContextAddLineToPoint(context, x + 3, size.height);
		CGContextStrokePath(context);
	}
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
	InstrumentFactory *defaultFactory = [InstrumentFactory defaultFactory];
	_guitar = [[Guitar alloc] init];
	[_guitar reloadInstruments:defaultFactory];
	for (i = 0; i < FINGER_SLOTS; i++) {
		fingers[i] = [[FingerImpl alloc] init:self];
	}
	for (i = 0; i < MAX_FRETS; i++) {
//		float p = 1.0 - 1.0 / pow(pow(2.0, i), 1.0 / 12);
//		fretPositions[i] = p / SCALE_FACTOR * rect.size.height + NUT_OFFSET;
		fretPositions[i] = NUT_OFFSET + i * FRET_SIZE;
	}
	[_guitar start];
    UIView *fingerView = [[FingerView alloc] initWithFrame:rect];
	[fingerView setOpaque:FALSE];
    [self addSubview:fingerView];
	[NSTimer scheduledTimerWithTimeInterval:0.2
		 target:fingerView
		 selector:@selector(setNeedsDisplay) 
		 userInfo:nil 
		 repeats:YES];
	[fingerView setEnabledGestures: TRUE];

	sliderView = [[VolumeSliderView alloc] initWithFrame:CGRectMake(100, 0, rect.size.width - 100, NUT_OFFSET)];
	[sliderView setDelegate:self];
	[self addSubview:sliderView];

	return self;
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
	CGSize size = [self bounds].size;
	int string = (point.x - FRET_MARGIN) / (size.width - FRET_MARGIN * 2) * STRINGS;
	if (string < 0) string = 0;
	if (string > STRINGS - 1) string = STRINGS - 1;
	return string;
}

- (float)fretPositionAt:(int)index {
	return fretPositions[index];
}

- (void)reloadInstruments:(InstrumentFactory*)factory {
	NSLog(@"reloadInstruments");
	[_guitar reloadInstruments:factory];
}

@end
