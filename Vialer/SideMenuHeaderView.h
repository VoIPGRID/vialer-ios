//
//  SideMenuHeaderView.h
//  Vialer
//
//  Created by Bob Voorneveld on 25/09/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SideMenuHeaderView : UIView

@property (strong, nonatomic) UIColor *tintColor;
@property (strong, nonatomic) NSString *displayName;
@property (strong, nonatomic) NSString *phoneNumber;

- (instancetype)initWithFrame:(CGRect)frame andTintColor:(UIColor *)tintColor;

@end
