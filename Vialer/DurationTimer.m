//
//  DurationTimer.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "DurationTimer.h"

@interface DurationTimer()
@property (copy, nonatomic) durationTimerStatusUpdateBlock durationTimerStatusUpdateBlock;
@property (strong, nonatomic) NSTimer *durationTimer;
@property (strong, nonatomic) NSDate *startDate;
@property (nonatomic) NSTimeInterval timeInterval;
@end

@implementation DurationTimer

# pragma mark - Life view cycle

- (void)dealloc {
    [self stop];
}

- (instancetype)initDurationTimerWithTimeInterval:(NSTimeInterval)timeInterval andDurationTimerStatusUpdateBlock:(durationTimerStatusUpdateBlock)durationTimerStatusUpdateBlock {
    self = [super init];
    if (self) {
        self.timeInterval = timeInterval;
        self.durationTimerStatusUpdateBlock = durationTimerStatusUpdateBlock;
    }
    return self;
}

- (instancetype)initAndStartDurationTimerWithTimeInterval:(NSTimeInterval)timeInterval andDurationTimerStatusUpdateBlock:(durationTimerStatusUpdateBlock)durationTimerStatusUpdateBlock {
    self = [self initDurationTimerWithTimeInterval:timeInterval andDurationTimerStatusUpdateBlock:durationTimerStatusUpdateBlock];
    if (self) {
        [self start];
    }
    return self;
}

# pragma mark - actions

- (void)start {
    self.startDate = [NSDate date];
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeInterval
                                                          target:self
                                                        selector:@selector(durationTimerUpdate:)
                                                        userInfo:nil
                                                         repeats:YES];
}

- (void)stop {
    [self.durationTimer invalidate];
    self.durationTimer = nil;
    self.startDate = nil;
    self.durationTimerStatusUpdateBlock = nil;
}

- (void)durationTimerUpdate:(id)sender {
    if (self.durationTimerStatusUpdateBlock) {
        self.durationTimerStatusUpdateBlock(-[self.startDate timeIntervalSinceNow]);
    }
}
@end
