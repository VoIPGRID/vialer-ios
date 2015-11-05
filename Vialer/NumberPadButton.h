//
//  NumberPadButton.h
//  Vialer
//
//  Created by Bob Voorneveld on 03/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface NumberPadButton : UIButton

@property (nonatomic, strong) IBInspectable NSString *number;
@property (nonatomic, strong) IBInspectable NSString *subtitle;

@end
