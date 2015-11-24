//
//  UIAlertController+Vialer.m
//  Vialer
//
//  Created by Bob Voorneveld on 19/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "UIAlertController+Vialer.h"

@implementation UIAlertController (Vialer)

+ (UIAlertController *)alertControllerWithTitle:(NSString *)title message:(NSString *)message andDefaultButtonText:(NSString *)defaultButtonText {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:defaultButtonText style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:defaultAction];
    return alert;
}

@end
