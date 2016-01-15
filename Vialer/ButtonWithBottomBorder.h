//
//  ButtonWithBottomBorder.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface ButtonWithBottomBorder : UIButton

@property (strong, nonatomic) IBInspectable UIColor *borderColor;
@property (nonatomic) IBInspectable CGFloat borderSize;

@end
