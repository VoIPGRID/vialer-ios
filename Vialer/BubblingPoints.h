//
//  BubblingPoints.h
//  2stepscreen
//
//  Created by Bob Voorneveld on 15/10/15.
//  Copyright © 2015 Bob Voorneveld. All rights reserved.
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
