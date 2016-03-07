//
//  DurationTimer.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DurationTimer : NSObject

/**
 *  The type definition for the completion block.
 *
 *  @return duration NSInteger how many seconds the timer has been running.
 */
typedef void (^durationTimerStatusUpdateBlock)(NSInteger durationTimer);

/**
 *  Make the init unavailable.
 *
 *  @return compiler error.
 */
-(instancetype _Nullable) init __attribute__((unavailable("init not available. Use initAndStartDurationTimerWithTimerInterval instead.")));

/**
 *  Init the class and also start the timer with the given duration and the completion block to use
 *
 *  @param timeInterval               NSTimeInterval after how many seconds the selector will be called again
 *  @param andDurationTimerCompletion The completion block which will be called.
 */
- (instancetype _Nullable)initAndStartDurationTimerWithTimeInterval:(NSTimeInterval)timeInterval andDurationTimerStatusUpdateBlock:(durationTimerStatusUpdateBlock _Nullable)durationTimerStatusUpdateBlock;

/**
 *  Stop the timer
 */
- (void)stop;
@end
