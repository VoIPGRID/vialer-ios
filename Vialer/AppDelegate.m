//
//  AppDelegate.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "AppDelegate.h"

#import "AFNetworkActivityLogger.h"
#import "APNSHandler.h"
#import <AudioToolbox/AudioServices.h>
@import CoreData;
#import "GAITracker.h"
#import "HDLumberjackLogFormatter.h"
#import "PhoneNumberModel.h"
#ifdef DEBUG
#import "SDStatusBarManager.h"
@import Contacts;
#endif
#import "SIPUtils.h"
#import "SSKeychain.h"
#import "SVProgressHUD.h"
#import "SystemUser.h"
#import <VialerSIPLib-iOS/VialerSIPLib.h>

@interface AppDelegate()
@property (readwrite, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readwrite, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readwrite, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) UIBackgroundTaskIdentifier vibratingTask;
@property (nonatomic) BOOL stopVibrating;
@property (strong, nonatomic) UILocalNotification *incomingCallNotification;
@end

NSString * const AppDelegateIncomingCallNotification = @"AppDelegateIncomingCallNotification";
NSString * const AppDelegateIncomingBackgroundCallNotification = @"AppDelegateIncomingBackgroundCallNotification";
NSString * const AppDelegateLocalNotificationCategory = @"AppDelegateLocalNotificationCategory";
NSString * const AppDelegateLocalNotificationAcceptCall = @"AppDelegateLocalNotificationAcceptCall";
NSString * const AppDelegateLocalNotificationDeclineCall = @"AppDelegateLocalNotificationDeclineCall";
static NSTimeInterval const AppDelegateVibratingTimeInterval = 2.0f;
static int const AppDelegateNumberOfVibrations = 5;

@implementation AppDelegate

#pragma mark - UIApplication delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupCocoaLumberjackLogging];

    [SSKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlock];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];

    // Only when the app is run for screenshot purposes do the following:
    if ([[self class] isSnapshotScreenshotRun]) {
#ifdef DEBUG
        [[SDStatusBarManager sharedInstance] setTimeString:@"09:41"];
        [[SDStatusBarManager sharedInstance] enableOverrides];

        // This is a fix for screenshot automation. It won't accept the "would like to access contacts" alert
        // if it is presented at the normal point in the app.
        CNContactStore *contactStore = [[CNContactStore alloc] init];
        [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            NSLog(@"Contacts access granted: %@", granted ? @"YES" : @"NO");
        }];
#endif
        [GAITracker setupGAITrackerWithLogLevel:kGAILogLevelNone andDryRun:YES];

        // Clear out the userdefaults.
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeLocalNotification:) name:VSLCallConnectedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeLocalNotification:) name:VSLCallDisconnectedNotification object:nil];

    [[APNSHandler sharedHandler] registerForVoIPNotifications];

    [self setupCallbackForVoIPNotifications];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[SystemUser currentUser] updateSystemUserFromVGWithCompletion:nil];
        // No completion necessary, because an update will follow over the "SystemUserSIPCredentialsChangedNotifications".

        VSLCall *call = [SIPUtils getFirstActiveCall];
        if (call.callState == VSLCallStateIncoming) {
            [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateIncomingCallNotification object:call];
        }
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self stopVibratingInBackground];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    VSLCall *call = [SIPUtils getFirstActiveCall];
    if (call && call.callState == VSLCallStateIncoming) {
        [self createLocalNotificationForCall:call];
    }
    [self saveContext];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler {
    [self stopVibratingInBackground];
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
    UIColor *green = [UIColor colorWithRed:(0/255.0) green:(255/255.0) blue:(0/255.0) alpha:1.0];
    [[DDTTYLogger sharedInstance] setForegroundColor:green backgroundColor:nil forFlag:DDLogFlagDebug];
    UIColor *red = [UIColor colorWithRed:(255/255.0) green:(0/255.0) blue:(0/255.0) alpha:1.0];
    [[DDTTYLogger sharedInstance] setForegroundColor:red backgroundColor:nil forFlag:DDLogFlagError];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor darkGrayColor] backgroundColor:nil forFlag:DDLogFlagVerbose];

#ifdef DEBUG
    // File logging
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.maximumFileSize = 1024 * 1024 * 1; // Size in bytes
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
    acceptCall.activationMode = UIUserNotificationActivationModeForeground;
    acceptCall.title = NSLocalizedString(@"Accept", nil);
    acceptCall.identifier = AppDelegateLocalNotificationAcceptCall;
    acceptCall.destructive = NO;
    acceptCall.authenticationRequired = NO;

    UIMutableUserNotificationAction *declineCall = [[UIMutableUserNotificationAction alloc] init];
    declineCall.activationMode = UIUserNotificationActivationModeBackground;
    declineCall.title = NSLocalizedString(@"Decline", nil);
    declineCall.identifier = AppDelegateLocalNotificationDeclineCall;
    declineCall.destructive = NO;
    declineCall.authenticationRequired = NO;

    UIMutableUserNotificationCategory *noticationCategory = [[UIMutableUserNotificationCategory alloc] init];
    noticationCategory.identifier = AppDelegateLocalNotificationCategory;
    [noticationCategory setActions:@[acceptCall, declineCall] forContext: UIUserNotificationActionContextDefault];

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
            if ([SIPUtils anotherCallInProgress:call]) {
                DDLogInfo(@"There is another call in progress. For now declining the call that is incoming.");

                NSError *error;
                [call decline:&error];
                if (error) {
                    DDLogError(@"Error declining call: %@", error);
                }
            } else {
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                    [self createLocalNotificationForCall:call];
                    [self startVibratingInBackground];
                } else {
                    DDLogDebug(@"Call received with device in foreground. Call: %ld", (long)call.callId);
                    [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateIncomingCallNotification object:call];
                }
            }
        });
    };
}

- (void)createLocalNotificationForCall:(VSLCall *)call {
    // The notification
    self.incomingCallNotification = [[UILocalNotification alloc] init];
    NSDictionary *myUserInfo = @{@"callId": [NSString stringWithFormat:@"%ld", (long)call.callId]};
    self.incomingCallNotification.userInfo = myUserInfo;
    self.incomingCallNotification.alertTitle = NSLocalizedString(@"Incoming call", nil);
    self.incomingCallNotification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"Incoming call from: %1@ <%2@>", @"Incoming call from: 'callerName', <'callerNumber'>"), call.callerName, call.callerNumber];
    self.incomingCallNotification.alertLaunchImage = @"AppIcon";
    self.incomingCallNotification.soundName = @"ringtone.wav";
    self.incomingCallNotification.category = AppDelegateLocalNotificationCategory;

    [[UIApplication sharedApplication] scheduleLocalNotification:self.incomingCallNotification];
}

- (void)removeLocalNotification:(UILocalNotification *)notification {
    [[UIApplication sharedApplication] cancelLocalNotification:self.incomingCallNotification];
    [self stopVibratingInBackground];
}

- (void)startVibratingInBackground {
    UIApplication *application = [UIApplication sharedApplication];

    // Vibrating
    self.stopVibrating = NO;
    self.vibratingTask = [application beginBackgroundTaskWithExpirationHandler:^{
        self.stopVibrating = YES;
        [application endBackgroundTask:self.vibratingTask];
        self.vibratingTask = UIBackgroundTaskInvalid;
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (int i = 0; i < AppDelegateNumberOfVibrations; i++) {
            if (self.stopVibrating) {
                break;
            }
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            [NSThread sleepForTimeInterval:AppDelegateVibratingTimeInterval];
        }
        [application endBackgroundTask:self.vibratingTask];
        self.vibratingTask = UIBackgroundTaskInvalid;
    });
}

- (void)stopVibratingInBackground {
    self.stopVibrating = YES;
    [[UIApplication sharedApplication] endBackgroundTask:self.vibratingTask];
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
