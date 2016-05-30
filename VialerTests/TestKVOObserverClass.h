//
//  TestKVOObserverClass.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  This classs was created so KVO notification can be tested.
 *  This is not possible directly on a NSObject mock because of a known limitation of OCMock.
 *
 *  OCMock 10.6 Methods on NSObject cannot be verified
 *  It is not possible use verify-after-running with methods implemented in NSObject or a category on it.
 *  In some cases it is possible to stub the method and then verify it. It is possible to use
 *  verify-after-running when the method is overriden in a subclass.
 */

@interface TestKVOObserverClass : NSObject

@end
