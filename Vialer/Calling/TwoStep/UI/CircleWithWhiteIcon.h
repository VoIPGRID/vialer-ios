//
//  CircleWithWhiteIcon.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CircleWithWhiteIcon : UIView

/**
 The color of the inner circle.
*/
@property (nonatomic, strong) UIColor *innerCircleColor;

/**
 The icon that is placed on top of the circle.
*/
@property (nonatomic, strong) UIImage *icon;

@end
