//
//  AudioOutput.h
//
//  Created by shinya on 07/12/23.
//

#import <Cocoa/Cocoa.h>

#import "AudioQueue.h"

#define SAMPLING_RATE 44100
#define FRAMES 512
#define BUFFERS 3

typedef short AudioSample;

@interface AudioOutput : NSObject {
	NSMutableArray *channels;
	AudioQueueRef outAQ;
	AudioQueueBufferRef mBuffers[BUFFERS];
}

- (void)start;
- (void)fillBuffer:(AudioSample*)buffer frames:(int)frames;

@end
