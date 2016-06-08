//
//  TestKVOObserverClass.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "TestKVOObserverClass.h"

@implementation TestKVOObserverClass

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {}
- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {}
@end
