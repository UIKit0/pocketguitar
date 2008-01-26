//
//  AudioOutput.m
//
//  Created by shinya on 07/12/23.
//

#import "AudioOutput.h"
#import <UIKit/UIKit.h>
#import <GraphicsServices/GraphicsServices.h>
#import <Celestial/AVSystemController.h>
#import <Celestial/AVController.h>
#import <Celestial/AVItem.h>
#include "MobileMusicPlayer/MobileMusicPlayer.h"

@implementation AudioOutput

static void AQBufferCallback(void *aqData, AudioQueueRef queue, AudioQueueBufferRef buffer) {
	AudioOutput *dev = (AudioOutput*)aqData;
	AudioSample *coreAudioBuffer = (AudioSample*) buffer->mAudioData;
	buffer->mAudioDataByteSize = sizeof(AudioSample) * 2 * FRAMES;
    [dev fillBuffer:coreAudioBuffer frames:FRAMES];
	AudioQueueEnqueueBuffer(queue, buffer, 0, NULL);
}

- (void)fillBuffer:(AudioSample*)buffer frames:(int)frames {
}

-(void)start {
	int status;
	int i;
	NSLog(@"AudioOutput start\n");
	
	AudioStreamBasicDescription desc;
	desc.mSampleRate = SAMPLING_RATE;
	desc.mFormatID = kAudioFormatLinearPCM;
	desc.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger  | kAudioFormatFlagIsPacked;
	desc.mBytesPerPacket = 4;
	desc.mFramesPerPacket = 1;
    desc.mBytesPerFrame = 4;
	desc.mChannelsPerFrame = 2;
	desc.mBitsPerChannel = 16;
	
    // single thread
    // AudioQueueNewOutput(&desc, AQBufferCallback, self, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &outAQ);
    
    // multithread
    status = AudioQueueNewOutput(&desc, AQBufferCallback, self, NULL, kCFRunLoopCommonModes, 0, &outAQ);
	if (status) [NSException raise:@"AudioOutputError" format:@"AudioQueueNewOutput failed: %d", status];
	status = AudioQueueSetParameter(outAQ, kAudioQueueParam_Volume, 1.0);
    if (status) [NSException raise:@"AudioOutputError" format:@"AudioQueueSetParameter failed: %d", status];
	
	UInt32 bufferBytes  = FRAMES * desc.mBytesPerFrame;
	for (i = 0; i < BUFFERS; i++) {
		status = AudioQueueAllocateBuffer(outAQ, bufferBytes, &mBuffers[i]);
        if (status) [NSException raise:@"AudioOutputError" format:@"AudioQueueAllocateBuffer failed: %d", status];
		AQBufferCallback(self, outAQ, mBuffers[i]);
	}

    status = AudioQueueStart(outAQ, NULL);
    if (status) [NSException raise:@"AudioOutputError" format:@"AudioQueueStart failed: %d", status];
}

-(id)init {
	channels = [NSMutableArray new];
	return self;
}

/*
 * The system volume does not take effect until any sound is played with AVController,
 * so we'll play a silent sound here
 */
+ (void)initSystemVolume {
	AVSystemController *avsc = [AVSystemController sharedAVSystemController];
	float volume;
	NSString *name;
	[avsc getActiveCategoryVolume:&volume andName:&name];
	NSLog(@"volume=%f name=%@", volume, name);
	NSLog(@"route=%@", [avsc routeForCategory:@"Audio/Video"]);
	
	int playbackState = PCGetPlaybackState();
	NSLog(@"state=%d", playbackState);

	if (kPlayerPlaying != playbackState) {
//		[avsc setActiveCategoryVolumeTo:0.6];
		AVController *avc = [AVController avController];
		NSError *error;
		AVItem *silence = [[AVItem alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"silence" ofType:@"wav"] error:&error];
		[avc setCurrentItem:silence preservingRate:NO];
		[avc setCurrentTime:0.0];
		[avc play:nil];
		[avc pause];
//		[avc release];
/*	[avc setVolume:0.8];
//	[avc pause];
*/
	}
}

@end
