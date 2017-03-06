//
//  ColoredUIButton.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RoundedAndColoredUIButton : UIButton

@property (nonatomic) UIColor *backgroundColorForPressedState;
@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic) UIColor *borderColor;

@end
