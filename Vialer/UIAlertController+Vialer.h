//
//  UIAlertController+Vialer.h
//  Vialer
//
//  Created by Bob Voorneveld on 19/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (Vialer)

+ (UIAlertController *)alertControllerWithTitle:(NSString *)title message:(NSString *)message andDefaultButtonText:(NSString *)defaultButtonText;
@end
