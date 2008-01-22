//
//  Fretboard.h
//  PocketGuitar
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <GraphicsServices/GraphicsServices.h>

#define DEFAULT_NUT_OFFSET 30
#define DRAG_FRET 3

@interface Fretboard : NSObject {
	int _fretCount;
	int _stringCount;
	float _distanceBetweenFrets;
	float _stringMargin;
	float _displayHeight;
	float _displayOffset;
	CGRect _rect;
}

- (id)initWithRect:(CGRect)rect;
- (int)fretCount;
- (int)stringCount;
- (float)fretPositionAt:(int)fret;
- (float)stringPositionAt:(int)string;
- (float)stringMargin;
- (float)displayHeight;
- (float)displayOffset;
- (float)pickupOffset;
- (float)fretFromPosition:(float)position;
- (float)stringFromPosition:(float)position;
- (int)stringIndexFromPosition:(float)position;
- (void)setDistanceBetweenFrets:(float)distance;
- (void)setDisplayHeight:(float)height;
- (void)reload;
- (void)save;
- (void)loadDefault;
- (void)drawRect:(CGRect)rect withContext:(CGContextRef)context andEnableDrag:(BOOL)drag;
- (CGSize)size;
- (void)setStringMargin:(float)margin;

@end
