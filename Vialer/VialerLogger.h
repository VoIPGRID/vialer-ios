//
//  VialerLogger.h
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

/**
 *  A custom logger to make remote and console logging easy.
 */
@interface VialerLogger : NSObject

/**
 *  Macros for easy use in Objective C code
 */
#define VialerLog(flag, fnct, frmt, ...)   \
[VialerLogger logWithFlag:flag file:__FILE__ function:fnct line:__LINE__ format:(frmt), ## __VA_ARGS__]

#define VialerLogVerbose(frmt, ...) VialerLog(DDLogFlagVerbose, __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)
#define VialerLogDebug(frmt, ...)   VialerLog(DDLogFlagDebug,   __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)
#define VialerLogInfo(frmt, ...)    VialerLog(DDLogFlagInfo,    __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)
#define VialerLogWarning(frmt, ...) VialerLog(DDLogFlagWarning, __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)
#define VialerLogError(frmt, ...)   VialerLog(DDLogFlagError,   __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)

/**
 Log a message to the console, optionally also to remote

 @param flag Log level
 @param file The file where the log was dispatched
 @param function The function where the log was dispatched
 @param line The line where the log was dispatched
 @param format Formatted string, various arguments will be added to the string
 */
+ (void)logWithFlag:(DDLogFlag)flag
               file:(const char *_Nonnull)file
           function:(const char *_Nonnull)function
               line:(NSUInteger)line
             format:(NSString *_Nonnull)format, ... NS_FORMAT_FUNCTION(5,6);

/**
 Log a message to the console, optionally also to remote
 @param flag Log level
 @param file The file where the log was dispatched
 @param function The function where the log was dispatched
 @param line The line where the log was dispatched
 @param message Formatted string, various arguments will be added to the string
 */
+ (void)logWithFlag:(DDLogFlag)flag
               file:(const char *_Nonnull)file
           function:(const char *_Nonnull)function
               line:(NSUInteger)line
            message:(NSString *_Nonnull)message NS_SWIFT_NAME(log(flag:file:function:line:message:));

/**
 Log a message to the console, optionally also to remote

 @param flag Log level
 @param file The file where the log was dispatched
 @param function The function where the log was dispatched
 @param line The line where the log was dispatched
 @param format Formatted string, 
 @param arguments will be added to the string
 */
+ (void)logWithFlag:(DDLogFlag)flag
               file:(const char *_Nonnull)file
           function:(const char *_Nonnull)function
               line:(NSUInteger)line
             format:(NSString *_Nonnull)format
          arguments:(va_list)arguments NS_SWIFT_NAME(log(flag:file:function:line:format:arguments:));


/**
 Log a Lumberjack message

 @param message DDLogMessage instance
 */
+ (void)logWithDDLogMessage:(DDLogMessage *_Nonnull)message NS_SWIFT_NAME(log(message:));

/**
 Setup logging for the app
 */
+ (void)setup;

/**
 Returns if remote logging is enabled

 @return YES if remote logging is enabled
 */
+ (BOOL)remoteLoggingEnabled;

/**
 Set remote logging on or of

 @param enable If YES, remote logging will be enabled
 */
+ (void)setRemoteLoggingEnabled:(BOOL)enable;

/**
 Unique identifer that is used with the remote logging

 @return An unique identifier
 */
+ (NSString * _Nonnull)remoteIdentifier;

@end
