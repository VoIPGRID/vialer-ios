//
//  VoIPGRIDRequestOperationManager+Recents.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "VoIPGRIDRequestOperationManager.h"

@interface VoIPGRIDRequestOperationManager (Recents)

/**
 *  This method will try to remotely fetch the last calls of the Client the currently authenticated user belongs to.
 *
 *  @param parameters A dictionary with parameters that are sent along with the request.
 *  @param completion A block that will be called after the fetch attempt. It will return the response data if any or an error if any.
 */
- (void)cdrRecordsWithParameters:(NSDictionary *)parameters withCompletion:(void (^)(AFHTTPRequestOperation *operation, NSDictionary *responseData, NSError *error))completion;

@end
