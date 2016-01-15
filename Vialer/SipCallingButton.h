//
//  SipCallingButton.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface SipCallingButton : UIButton

/**
 The image that will be set inside the circle. This will be a 
 property in the storyboard.
 */
@property (nonatomic, strong) IBInspectable NSString *buttonImage;

@end
