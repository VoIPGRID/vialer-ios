//
//  ContactUtils.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContactsUI/ContactsUI.h"

@interface ContactUtils : NSObject

/**
 *  Formatted string of the contact to display.
 *
 *  @param contact CNContact instance.
 *
 *  @return Parts of the string bolded based on the phone settings for family or given name.
 */
+ (NSMutableAttributedString * _Nonnull)getFormattedStyledContact:(CNContact * _Nonnull)contact;

/**
 *  Get the name to display for a contact.
 *
 *  @param contact CNContact instance
 *
 *  @return NSString of either the fullname or the email address.
 */
+ (NSString * _Nullable)getDisplayNameForContact:(CNContact * _Nonnull)contact;
@end
