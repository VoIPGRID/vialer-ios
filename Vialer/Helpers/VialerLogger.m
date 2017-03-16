//
//  VialerLogger.h
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

#import "VialerLogger.h"

#import "lelib.h"
#import "SPLumberjackLogFormatter.h"
@import UIKit;
#import "Vialer-Swift.h"


static NSString * const DDLogWrapperShouldUseRemoteLoggingKey = @"DDLogWrapperShouldUseRemoteLogging";


@implementation VialerLogger

+ (void)setup {
    le_init();
    le_handle_crashes();
    le_set_token([[[Configuration defaultConfiguration] logEntriesToken] UTF8String]);

    SPLumberjackLogFormatter *logFormatter = [[SPLumberjackLogFormatter alloc] init];

    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    [ttyLogger setLogFormatter:logFormatter];

    [DDLog addLogger:ttyLogger];

    // LogEntries
    LELog* logger = [LELog sharedInstance];
    logger.debugLogs = NO;

#ifdef DEBUG
    // File logging
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.maximumFileSize = 1024 * 1024 * 1; // Size in bytes
    fileLogger.rollingFrequency = 0; // Set rollingFrequency to 0, only roll on file size.
    [fileLogger logFileManager].maximumNumberOfLogFiles = 3;
    fileLogger.logFormatter = logFormatter;
    [DDLog addLogger:fileLogger];
#endif

    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.isScreenshotRun) {
        [VialerGAITracker setupGAITrackerWithLogLevel:kGAILogLevelNone isDryRun:YES];
    } else {
        [VialerGAITracker setupGAITracker];
    }

    [VialerSIPLib sharedInstance].logCallBackBlock = ^(DDLogMessage *_Nonnull message) {
        [VialerLogger logWithDDLogMessage:message];
    };
}

+ (void)logWithFlag:(DDLogFlag)flag file:(const char*)file function:(const char *)function line:(NSUInteger)line format:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self logWithFlag:flag file:file function:function line:line format:format arguments:args];
    va_end(args);
}

+ (void)logWithFlag:(DDLogFlag)flag file:(const char*)file function:(const char *)function line:(NSUInteger)line message:(NSString *)message {
    [self logWithFlag:flag file:file function:function line:line format:message arguments:nil];
}

+ (void)logWithFlag:(DDLogFlag)flag file:(const char *)file function:(const char *)function line:(NSUInteger)line format:(NSString *)format arguments:(va_list)arguments {
    NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
    NSString *logFile = [NSString stringWithFormat:@"%s", file];
    NSString *logFunction = [NSString stringWithFormat:@"%s", function];

    // Add in the Connection type.
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    message = [NSString stringWithFormat:@"[%@] %@", delegate.reachability.statusString, message];

    DDLogMessage *logMessage = [[DDLogMessage alloc] initWithMessage:message
                                                               level:LOG_LEVEL_DEF
                                                                flag:flag
                                                             context:0
                                                                file:logFile
                                                            function:logFunction
                                                                line:line
                                                                 tag:nil
                                                             options:(DDLogMessageOptions)0
                                                           timestamp:nil];

    [[DDLog sharedInstance] log:LOG_ASYNC_ENABLED message:logMessage];
    [self logMessageToLogEntriesWitMessage:logMessage];
}

+ (void)logWithDDLogMessage:(DDLogMessage *)message {
    // Add in the Connection type.
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    message->_message = [NSString stringWithFormat:@"[%@] %@", delegate.reachability.statusString, message.message];
    [[DDLog sharedInstance] log:LOG_ASYNC_ENABLED message:message];
    [self logMessageToLogEntriesWitMessage:message];
}

+ (BOOL)remoteLoggingEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:DDLogWrapperShouldUseRemoteLoggingKey];
}

+ (void)setRemoteLoggingEnabled:(BOOL)enable {
    [[NSUserDefaults standardUserDefaults] setBool:enable forKey:DDLogWrapperShouldUseRemoteLoggingKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)remoteIdentifier {
    return [[[UIDevice currentDevice].identifierForVendor UUIDString] substringToIndex:8];
}

#pragma mark - Helper Functions

/**
 Log to LogEntries if user has enabled.

 @param flag LogLevel
 @param message NSString to sent to LogEntries
 */
+ (void)logMessageToLogEntriesWitMessage:(DDLogMessage *)message {
    // Check if remote logging is enabled
    if (![[NSUserDefaults standardUserDefaults] boolForKey:DDLogWrapperShouldUseRemoteLoggingKey]) {
        return;
    }

    NSString *logFile = [[[NSURL URLWithString:message.file] lastPathComponent] stringByDeletingPathExtension];
    NSString *logMessage = [NSString stringWithFormat:@"[%@ %@: %lu] %@", logFile, message.function, (unsigned long)message.line, message.message];

    // Set loglevel to LogEntries label
    NSString *level;
    switch (message.flag) {
        case DDLogFlagVerbose:
            level = @"VERBOSE";
            break;
        case DDLogFlagDebug:
            level = @"DEBUG";
            break;
        case DDLogFlagInfo:
            level = @"INFO";
            break;
        case DDLogFlagWarning:
            level = @"WARNING";
            break;
        case DDLogFlagError:
            level = @"ERROR";
            break;
    }

    // Clean the message from privacy information.
    logMessage = [logMessage replaceRegexWithPattern:@"Token: <(.*)>" with:@"TOKEN"];
    logMessage = [logMessage replaceRegexWithPattern:@"\"caller_id\" = (.+?);" with:@"<CALLER_ID>"];
    logMessage = [logMessage replaceRegexWithPattern:@"phonenumber = (.+?);" with:@"<PHONE_NUMBER>"];
    logMessage = [logMessage replaceRegexWithPattern:@"To:(.+?)>" with:@" <SIP_ANONYMIZED"];
    logMessage = [logMessage replaceRegexWithPattern:@"From:(.+?)>" with:@" <SIP_ANONYMIZED"];
    logMessage = [logMessage replaceRegexWithPattern:@"Contact:(.+?)>" with:@" <SIP_ANONYMIZED"];
    logMessage = [logMessage replaceRegexWithPattern:@"sip:(.+?)@" with:@"SIP_USER_ID"];
    logMessage = [logMessage replaceRegexWithPattern:@"Digest username=\"(.+?)\"" with:@"SIP_USERNAME"];
    logMessage = [logMessage replaceRegexWithPattern:@"nonce=\"(.+?)\"" with:@"NONCE"];
    logMessage = [logMessage replaceRegexWithPattern:@"username=(.+?)&" with: @"USERNAME"];
    logMessage = [logMessage replaceRegexWithPattern:@"token=(.+?)&" with: @"TOKEN"];
    NSString *log = [NSString stringWithFormat:@"%@ %@ - %@", level, [VialerLogger remoteIdentifier], logMessage];
    [[LELog sharedInstance] log:log];
}

@end
