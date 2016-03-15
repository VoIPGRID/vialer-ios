//
//  AppDelegate.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "AppDelegate.h"

#import "AFNetworkActivityLogger.h"
#import "APNSHandler.h"
@import CoreData;
#import "GAITracker.h"
#import "HDLumberjackLogFormatter.h"
#ifdef DEBUG
#import "SDStatusBarManager.h"
#endif
#import "SIPUtils.h"
#import "SSKeychain.h"
#import "SystemUser.h"
#import <VialerSIPLib-iOS/VialerSIPLib.h>

@interface AppDelegate()
@property (readwrite, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readwrite, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readwrite, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@end

NSString * const AppDelegateIncomingCallNotification = @"AppDelegateIncomingCallNotification";
NSString * const AppDelegateIncomingBackgroundCallNotification = @"AppDelegateIncomingBackgroundCallNotification";
NSString * const AppDelegateLocalNotificationCategory = @"AppDelegateLocalNotificationCategory";
NSString * const AppDelegateLocalNotificationAcceptCall = @"AppDelegateLocalNotificationAcceptCall";
NSString * const AppDelegateLocalNotificationDeclineCall = @"AppDelegateLocalNotificationDeclineCall";

@implementation AppDelegate

#pragma mark - UIApplication delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupCocoaLumberjackLogging];

    [SSKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlock];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    //Only when the app is run for screenshot purposes do the following:
    if ([[self class] isSnapshotScreenshotRun]) {
#ifdef DEBUG
        [[SDStatusBarManager sharedInstance] setTimeString:@"09:41"];
        [[SDStatusBarManager sharedInstance] enableOverrides];
#endif
        [GAITracker setupGAITrackerWithLogLevel:kGAILogLevelNone andDryRun:YES];

        //Clear out the userdefaults
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    } else {
        [GAITracker setupGAITracker];
    }

#ifdef DEBUG
    // Network logging
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelInfo];
#endif

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatedSIPCredentials:) name:SystemUserSIPCredentialsChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sipDisabledNotification:) name:SystemUserSIPDisabledNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedOut:) name:SystemUserLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextSaved:) name:NSManagedObjectContextDidSaveNotification object:nil];

    [[APNSHandler sharedHandler] registerForVoIPNotifications];

    [self setupCallbackForVoIPNotifications];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[SystemUser currentUser] updateSIPAccountWithCompletion:nil];
        // No completion necessary, because an update will follow over the "SystemUserSIPCredentialsChangedNotifications".

        VSLCall *call = [SIPUtils getFirstActiveCall];
        if (call.callState == VSLCallStateIncoming) {
            [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateIncomingCallNotification object:call];
        }
    });
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self saveContext];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler {
    if ([identifier isEqualToString:AppDelegateLocalNotificationAcceptCall] || [identifier isEqualToString:AppDelegateLocalNotificationDeclineCall]) {
        DDLogVerbose(@"User accepted a local notification with Action Identifier: %@", identifier);
        [self handleIncomingLocalBackgroudNotifications:identifier forCallId:notification.userInfo[@"callId"]];
    } else {
        DDLogDebug(@"Unsupported action for local Notification: %@", identifier);
    }
    completionHandler();
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    DDLogVerbose(@"Notification clicked without \"Action Identifier\" : %@", notification);
    if (notification.userInfo[@"callId"]) {
        [self handleIncomingLocalBackgroudNotifications:nil forCallId:notification.userInfo[@"callId"]];
    }
}

#pragma mark - setup helper methods

+ (BOOL)isSnapshotScreenshotRun {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"FASTLANE_SNAPSHOT"];
}

- (void)handleIncomingLocalBackgroudNotifications:(NSString *)notificationIdentifier forCallId:(NSString *)callId {
    VSLCall *call = [SIPUtils getCallWithId:callId];

    if (call.callState > VSLCallStateNull) {
        if ([notificationIdentifier isEqualToString:AppDelegateLocalNotificationDeclineCall]) {
            NSError *error;
            [call decline:&error];
            if (error) {
                DDLogError(@"Error declining call: %@", error);
            }
        } else if ([notificationIdentifier isEqualToString:AppDelegateLocalNotificationAcceptCall]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateIncomingBackgroundCallNotification object:call];
        } else if (!notificationIdentifier) {
            [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateIncomingCallNotification object:call];
        }
    }
}

- (void)setupCocoaLumberjackLogging {
    // Add the Terminal and TTY(XCode console) loggers to CocoaLumberjack (simulate the default NSLog behaviour)
    HDLumberjackLogFormatter* logFormat = [[HDLumberjackLogFormatter alloc] init];

    DDASLLogger *aslLogger = [DDASLLogger sharedInstance];
    [aslLogger setLogFormatter: logFormat];
    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    [ttyLogger setLogFormatter:logFormat];
    [ttyLogger setColorsEnabled:YES];

    // Give INFO a color
    UIColor *pink = [UIColor colorWithRed:(255/255.0) green:(58/255.0) blue:(159/255.0) alpha:1.0];
    [[DDTTYLogger sharedInstance] setForegroundColor:pink backgroundColor:nil forFlag:DDLogFlagInfo];

#ifdef DEBUG
    // File logging
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.maximumFileSize = 1024 * 1024 * 5; // Size in bytes
    fileLogger.rollingFrequency = 0; // Set rollingFrequency to 0, only roll on file size.
    [fileLogger logFileManager].maximumNumberOfLogFiles = 3;
    fileLogger.logFormatter = logFormat;
    [DDLog addLogger:fileLogger];
#endif

    [DDLog addLogger:aslLogger];
    [DDLog addLogger:ttyLogger];
}

# pragma mark - Notifications

- (void)updatedSIPCredentials:(NSNotification *)notification {
    DDLogInfo(@"SIP Credentials have changed");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([SystemUser currentUser].sipEnabled) {
            [SIPUtils setupSIPEndpoint];
            [[APNSHandler sharedHandler] registerForVoIPNotifications];
            [self registerForLocalNotifications];
        }
    });
}

- (void)sipDisabledNotification:(NSNotification *)notification {
    DDLogInfo(@"SIP has been disabled");
    dispatch_async(dispatch_get_main_queue(), ^{
        [SIPUtils removeSIPEndpoint];
    });
}

- (void)registerForLocalNotifications {
    UIMutableUserNotificationAction *acceptCall = [[UIMutableUserNotificationAction alloc] init];
    [acceptCall setActivationMode:UIUserNotificationActivationModeForeground];
    [acceptCall setTitle:@"Accept call"];
    [acceptCall setIdentifier:AppDelegateLocalNotificationAcceptCall];
    [acceptCall setDestructive:NO];
    [acceptCall setAuthenticationRequired:NO];

    UIMutableUserNotificationAction *declineCall = [[UIMutableUserNotificationAction alloc] init];
    [declineCall setActivationMode:UIUserNotificationActivationModeBackground];
    [declineCall setTitle:@"Decline call"];
    [declineCall setIdentifier:AppDelegateLocalNotificationDeclineCall];
    [declineCall setDestructive:NO];
    [declineCall setAuthenticationRequired:NO];

    UIMutableUserNotificationCategory *noticationCategory = [[UIMutableUserNotificationCategory alloc] init];
    [noticationCategory setIdentifier:AppDelegateLocalNotificationCategory];
    [noticationCategory setActions:@[acceptCall, declineCall] forContext:UIUserNotificationActionContextDefault];

    NSSet *categories = [NSSet setWithObjects:noticationCategory, nil];
    UIUserNotificationType types = (UIUserNotificationTypeAlert|
                                    UIUserNotificationTypeSound|
                                    UIUserNotificationTypeBadge);

    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:categories];

    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
}

- (void)userLoggedOut:(NSNotification *)notification {
    [SIPUtils removeSIPEndpoint];
}

- (void)managedObjectContextSaved:(NSNotification *)notification {
    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }];
}

- (void)setupCallbackForVoIPNotifications {
    [VialerSIPLib sharedInstance].incomingCallBlock = ^(VSLCall * _Nonnull call) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SIPUtils anotherCallInProgress:call];
            if ([SIPUtils anotherCallInProgress:call]) {
                DDLogInfo(@"There is another call in progress. For now declining the call that is incoming.");

                NSError *error;
                [call hangup:&error];
                if (error) {
                    DDLogError(@"Error declining call: %@", error);
                }
            } else {
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    NSDictionary *myUserInfo = @{@"callId": [NSString stringWithFormat:@"%ld", (long)call.callId]};
                    localNotification.userInfo = myUserInfo;
                    localNotification.alertTitle = NSLocalizedString(@"Incoming call", nil);
                    localNotification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"Incoming call from: %@", nil), [SIPUtils getCallName:call]];
                    localNotification.alertLaunchImage = @"AppIcon";
                    localNotification.soundName = @"ringtone.wav";
                    localNotification.category = AppDelegateLocalNotificationCategory;

                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                } else {
                DDLogDebug(@"Call received with device in forground. Call: %ld", (long)call.callId);
                    [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateIncomingCallNotification object:call];
                }
            }
        });
    };
}

#pragma mark - Core Data

- (void)saveContext {
    NSError *error;
    if (self.managedObjectContext && [self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
        DDLogWarn(@"Unresolved error while saving Context: %@", error);
        abort();
    }
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator) {
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            _managedObjectContext.persistentStoreCoordinator = coordinator;
        }
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (!_managedObjectModel) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"VialerModel" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (!_persistentStoreCoordinator) {
        NSURL *applicationsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *storeURL = [applicationsDirectory URLByAppendingPathComponent:@"Vialer.sqlite"];

        NSError *error;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            // For now, we will let the app crash and watch if this is happening during production. It doesn't break the app completely if the app crashes.recent
            DDLogWarn(@"Could not create PersistentStoreCoordinator instance. Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    return _persistentStoreCoordinator;
}

@end
