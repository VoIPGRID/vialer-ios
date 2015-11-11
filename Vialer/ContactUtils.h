//
//  ContactUtils.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContactsUI/ContactsUI.h"

@interface ContactUtils : NSObject <UINavigationControllerDelegate>
/*
 * Format the contact so that the first name is bold.
 */
+ (NSMutableAttributedString *)getFormattedStyledContact:(CNContact*)contact;

@end
