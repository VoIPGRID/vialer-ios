//
//  UIAlertController+Vialer.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (Vialer)

+ (UIAlertController *)alertControllerWithTitle:(NSString *)title message:(NSString *)message andDefaultButtonText:(NSString *)defaultButtonText;
@end
