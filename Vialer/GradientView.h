//
//  GradientView.h
//  Vialer
//
//  Created by Reinier Wieringa on 15/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface GradientView : UIView

@property (nonatomic, strong) IBInspectable UIColor *startColor;
@property (nonatomic, strong) IBInspectable UIColor *endColor;
@property (nonatomic, assign) IBInspectable CGFloat angle;

@end
