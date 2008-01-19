//
//  InstrumentFactory.h
//
//  Created by shinya on 08/01/06.
//

#import <Cocoa/Cocoa.h>

#ifndef STK_VOICER_H
@class Instrmnt;
@class Voicer;
@class Effect;
#endif

@interface InstrumentFactory : NSObject {

}
+ (id)defaultFactory;
+ (NSArray *)allInstruments;
@end

@interface InstrumentFactory ( FactoryMethods )
- (Instrmnt *)newInstrumentWithBaseFrequency:(float)freq;
- (NSString *)name;
@end
