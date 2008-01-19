#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GuitarApp.h"

int main(int argc, char *argv[]) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int ret = UIApplicationMain(argc, argv, [GuitarApp class]);
	[pool release];
	return ret;
}
