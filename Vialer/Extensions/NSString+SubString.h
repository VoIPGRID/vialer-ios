//
//  NSString+SubString.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SubString)

/**
 *  Returns YES if the given string is contained in this string.
 *
 *  @param string The string to search for.
 *
 *  @return YES if the given string is found in this string.
 */
- (BOOL)containsString:(NSString * _Nonnull)string;

/**
 *  Returns the substring between the 2 given strings.
 *
 *  @param startString The start string of the search pattern.
 *  @param endString   The end string of the search pattern.
 *
 *  @return Returns the substing which was found between the 2 given string or nil.
 */
- (NSString * _Nullable)substringBetweenString:(NSString * _Nonnull)startString andString:(NSString * _Nonnull)endString;

@end
