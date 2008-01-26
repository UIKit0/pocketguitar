//
//  FretboardEditor.m
//  PocketGuitar
//

#import "FretboardEditor.h"

#define MIN_FRET_SIZE 10
#define MIN_FRET_END 300
#define MAX_FRET_END 450
#define MIN_MARGIN -50
#define MAX_MARGIN 80

#define DRAG_HANDLE_SIZE 30

typedef enum {
	kGSFontTraitRegular = 0,
    kGSFontTraitItalic = 1,
    kGSFontTraitBold = 2,
    kGSFontTraitBoldItalic = (kGSFontTraitBold | kGSFontTraitItalic)
} GSFontTrait;

id GSFontCreateWithName(char *name, GSFontTrait traits, float size);

@implementation FretboardEditor

- (void)loadDefault {
	[_fretboard loadDefault];
	[self setNeedsDisplay];
}

- (void)done {
	[_delegate performSelector:@selector(fretboardEdited)];
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	
	UIPushButton* doneButton = [[UIPushButton alloc] initWithTitle:@"Done" autosizesToFit:NO];
	[doneButton setFrame: CGRectMake(0, 0, 100, 30)];
	[doneButton setTitleFont:(struct __GSFont*)GSFontCreateWithName("Helvetica", kGSFontTraitBold, 15.0f)];
	[doneButton addTarget:self action:@selector(done) forEvents:1];
	[doneButton setStretchBackground:YES];
	
	UIPushButton* defaultButton = [[UIPushButton alloc] initWithTitle:@"Default" autosizesToFit:NO];
	[defaultButton setFrame: CGRectMake(frame.size.width - 100, 0, 100, 30)];
	[defaultButton setTitleFont:(struct __GSFont*)GSFontCreateWithName("Helvetica", kGSFontTraitBold, 15.0f)];
	[defaultButton addTarget:self action:@selector(loadDefault) forEvents:1];
	[defaultButton setStretchBackground:YES];
	
	[self addSubview:doneButton];
	[self addSubview:defaultButton];
	return self;
}

- (void)setDelegate:(id)delegate {
	_delegate = delegate;
}

- (void)setFretboard:(Fretboard*)fretboard {
	_fretboard = fretboard;
}

static void drawArrowProc(CGContextRef context, float x, float y, float width, float height, 
                          void (moveTo)(CGContextRef context, float x, float y),
                          void (lineTo)(CGContextRef context, float x, float y)) {
	float lineMargin = 0.3;
	float arrowOffset = 0.6;
	moveTo(context, x + lineMargin * width, y);
	lineTo(context, x + lineMargin * width, y + arrowOffset * height);
	lineTo(context, x, y + arrowOffset * height);
	lineTo(context, x + 0.5 * width, y +  height);
	lineTo(context, x + width, y + arrowOffset * height);
	lineTo(context, x + (1.0 - lineMargin) * width, y + arrowOffset * height);
	lineTo(context, x + (1.0 - lineMargin) * width, y);
	lineTo(context, x + lineMargin * width, y);
	CGContextFillPath(context);
}

static void drawArrow(CGContextRef context, float x, float y, float width, float height) {
	drawArrowProc(context, x, y, width, height, CGContextMoveToPoint, CGContextAddLineToPoint);
}

static void sideMoveTo(CGContextRef context, float y, float x) {
	CGContextMoveToPoint(context, x, y);
}

static void sideLineTo(CGContextRef context, float y, float x) {
	CGContextAddLineToPoint(context, x, y);
}

static void drawHorizontalArrow(CGContextRef context, float x, float y, float width, float height) {
	drawArrowProc(context, y, x, height, width, sideMoveTo, sideLineTo);
}

static void drawLine(CGContextRef context, float x1, float y1, float x2, float y2) {
	CGContextMoveToPoint(context, x1, y1);
	CGContextAddLineToPoint(context, x2, y2);
	CGContextStrokePath(context);
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UICurrentContext();
	CGContextClearRect(context, [self bounds]);
	CGSize size = ((CGRect) [self bounds]).size;
	float y;
	
	[_fretboard drawRect:rect withContext:context andEnableDrag:YES];
	
	y = [_fretboard fretPositionAt:DRAG_FRET];
	CGContextSetLineWidth(context, 1);
	CGContextSetRGBFillColor(context, 1.0, 0.3, 0.3, 1);
	drawArrow(context, 10, y + 10, 50, 50);
	drawArrow(context, 10, y - 10, 50, -50);
	
	CGContextSetLineWidth(context, 4);
	CGContextSetRGBStrokeColor(context, 0.2, 1, 0.2, 1);
	CGContextSetRGBFillColor(context, 0.2, 1, 0.2, 1);
	drawLine(context, 0, [_fretboard displayOffset] + [_fretboard displayHeight], size.width, 
						[_fretboard displayOffset] + [_fretboard displayHeight]);

	y = [_fretboard displayOffset] + [_fretboard displayHeight];
	drawArrow(context, 10, y + 10, 50, 50);
	drawArrow(context, 10, y - 10, 50, -50);

	CGContextSetRGBStrokeColor(context, 1, 1, 0.1, 1);
	CGContextSetRGBFillColor(context, 1, 1, 0.1, 1);
	float stringCount = [_fretboard stringCount];
	float stringMargin = [_fretboard stringMargin];
	float x = ((float)(stringCount - 1) + 0.5) / stringCount * (size.width - stringMargin * 2) + stringMargin;
	drawHorizontalArrow(context, x - 10, 100, -50, 50);
	drawHorizontalArrow(context, x + 10, 100, 50, 50);
}

- (void)mouseDown:(GSEvent *)event {
	CGPoint point = GSEventGetLocationInWindow(event);
	float fretEndPos = [_fretboard pickupOffset];
	float dragFretPos = [_fretboard fretPositionAt:3];
	float lastStringPos = [_fretboard stringPositionAt:[_fretboard stringCount] - 1];
	if (fabs(fretEndPos - point.y) <= DRAG_HANDLE_SIZE) {
		_draggingFretEnd = YES;
		_dragOffset = fretEndPos - point.y;
	} else if (fabs(dragFretPos - point.y) <= DRAG_HANDLE_SIZE) {
		_draggingFrets = YES;
		_dragOffset = dragFretPos - point.y;
	} else if (fabs(lastStringPos - point.x) <= DRAG_HANDLE_SIZE) {
		_draggingStrings = YES;
		_dragOffset = lastStringPos - point.x;
	}
}

- (void)mouseUp:(GSEvent *)event {
	_draggingFrets = NO;
	_draggingFretEnd = NO;
	_draggingStrings = NO;
}

- (void)mouseDragged:(GSEvent *)event {
	CGPoint point = GSEventGetLocationInWindow(event);
	if (_draggingFretEnd) {
		float pos = point.y + _dragOffset;
		float dragFretPos = [_fretboard fretPositionAt:DRAG_FRET];
		if (MIN_FRET_END <= pos && pos <= MAX_FRET_END && dragFretPos + DRAG_HANDLE_SIZE < pos) {
			[_fretboard setDisplayHeight:(pos - [_fretboard displayOffset])];
		}
	} else if (_draggingFrets) {
		float dist = (point.y - [_fretboard displayOffset]) + _dragOffset;
		if (MIN_FRET_SIZE * 3 <= dist && dist <= [_fretboard displayHeight] - 30) {
			[_fretboard setDistanceBetweenFrets:(dist / 3)];
		}
	} else if (_draggingStrings) {
		float stringPoint = [_fretboard size].width - (point.x + _dragOffset);
		float cp = stringPoint * [_fretboard stringCount];
		float w = [_fretboard size].width;
		//float margin = (w - cp) / (2 - 4 * [_fretboard stringCount]);
		//float margin = (2 * cp - w) / (cp - 2);
		//float margin = [_fretboard size].width / 2 - [_fretboard stringCount] * stringPoint;
		//float margin = (stringPoint - 2 * [_fretboard stringCount] * w) / (1 - 4 * [_fretboard stringCount]);
		float margin = (2 * cp - w) / (2 * ([_fretboard stringCount] - 1));
		NSLog(@"drag strings %f %f", stringPoint, margin);
		if (MIN_MARGIN <= margin && margin <= MAX_MARGIN) {
			[_fretboard setStringMargin:margin];
		}
	}
	[self setNeedsDisplay];
}

@end
