//
//  VoIPGRIDRequestOperationManager+ForgotPassword.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "VoIPGRIDRequestOperationManager.h"

@interface VoIPGRIDRequestOperationManager (ForgotPassword)

/**
 *  This method will try to request for a pasword reset email sent to given email address.
 *
 *  @param email      The email address where the password reset is asked for.
 *  @param completion A block that will be called after request attempt. It will return the response data if any or an error if any.
 */
- (void)passwordResetWithEmail:(NSString *)email withCompletion:(void (^)(NSURLResponse *operation, NSDictionary *responseData, NSError *error))completion;

@end
