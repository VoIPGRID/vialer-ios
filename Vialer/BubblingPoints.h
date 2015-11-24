//
//  BubblingPoints.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BubblingPointsState) {
    BubblingPointsStateIdle,
    BubblingPointsStateConnecting,
    BubblingPointsStateConnected,
    BubblingPointsStateConnectionFailed
};

@interface BubblingPoints : UIView

/**
 The color of the bubbling points.
*/
@property (nonatomic, strong) UIColor *color;

/**
 The current state of the bubbling points.
 */
@property (nonatomic) BubblingPointsState state;

@end
