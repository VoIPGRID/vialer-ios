//
//  PhoneNumberUtils.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PhoneNumberUtils : NSObject

/**
 *  This method will return a NSCharacterSet without Digits.
 *
 *  @return a NSCharacterSet without Digits
 */
+ (NSCharacterSet * _Nonnull)digitsCharacterSet;

/**
 *  Calculate calling code prefixes (NOTE: Only works in some countries, like The Netherlands).
 *
 *  @return Array with possible prefixes.
 */
+ (NSArray * _Nullable)prefixes;

/**
 *  Remove the prefix from a phone number if there is one present.
 *
 *  @param phoneNumber NSString which needs the prefix removed if present.
 *
 *  @return NSString with the prefix removed
 */
+ (NSString * _Nonnull)removePrefixFromPhoneNumber:(NSString * _Nonnull)phoneNumber;

/**
 *  Clean the phone number so it's usable to setup a SIP call.
 *
 *  @param phoneNumber the phonenumber to be cleaned.
 *
 *  @return NSString a cleaned phonennumber
 */
+ (NSString * _Nullable)cleanPhoneNumber:(NSString *_Nonnull)phoneNumber;
@end
