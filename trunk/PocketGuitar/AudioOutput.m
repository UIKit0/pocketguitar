//
//  AudioOutput.m
//
//  Created by shinya on 07/12/23.
//

#import "AudioOutput.h"

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

@end
