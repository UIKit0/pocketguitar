#import <Foundation/Foundation.h>
#include <mpg123.h>
#include <unistd.h>
#include <fcntl.h>

#define BUFSIZE 8192

int extractSamples();
int convertMp3ToRaw(NSString *from, NSString *to);

int main(int argc, char *argv[]) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int ret = extractSamples();
	[pool release];
	return ret;
}

int extractSamples() {
	int ret;
	mpg123_init();
	
	NSString *baseDir = [NSString stringWithFormat:@"%@/Media/PocketGuitar", NSHomeDirectory()];
	NSFileManager *manager = [NSFileManager defaultManager];
	NSDirectoryEnumerator *enm = [manager enumeratorAtPath:baseDir];
	NSString *file, *path;
	while ((file = [enm nextObject])) {
		if ([[file pathExtension] isEqualToString:@"mp3"]) {
			path = [baseDir stringByAppendingPathComponent:file];
			if ((ret = convertMp3ToRaw(path, [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"raw"]))) {
				return ret;
			}
		}
	}
	return 0;
}

int convertMp3ToRaw(NSString *from, NSString *to) {
	mpg123_handle *mh;
	int error;
	int outfd;
	int ret;
	int result = 0;
	size_t done;
	unsigned char out[BUFSIZE];

	NSLog(@"Converting %@ to %@", from, to);
	
	mh = mpg123_new(NULL, &error);
	if (MPG123_OK != mpg123_open(mh, (char *)[from UTF8String])) {
		NSLog(@"failed to open file: %@", from);
		result = 1;
		goto error;
	}
	
	outfd = open([to UTF8String], O_WRONLY|O_CREAT, 0644);
	if (outfd < 0) {
		NSLog(@"failed to open file: %@", to);
		result = 1;
		goto close_in;
	}
	while (1) {
		ret = mpg123_read(mh, out, BUFSIZE, &done);
		if (MPG123_DONE == ret) {
			break;
		} else if (ret <= 0) {
			ret = write(outfd, out, done);
			if (ret < 0) {
				NSLog(@"failed to write to file: %@", to);
				result = 1;
				goto close_all;
			}
		} else {
			NSLog(@"failed to read file: %@", from);
			result = ret;
			goto close_all;
		}
	}
	
close_all:
	close(outfd);
close_in:
	mpg123_close(mh);
error:
	return result;
}
