//
//  ConnectionHandler.m
//  Vialer
//
//  Created by Reinier Wieringa on 19/12/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "ConnectionHandler.h"
#import "AppDelegate.h"
#import "VoIPGRIDRequestOperationManager.h"
#import "Gossip+Extra.h"

#import "AFNetworkReachabilityManager.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

NSString * const ConnectionStatusChangedNotification = @"com.vialer.ConnectionStatusChangedNotification";
NSString * const IncomingSIPCallNotification = @"com.vialer.IncomingSIPCallNotification";

NSString * const NotificationAcceptDeclineCategory = @"com.vialer.notification.accept.decline.category";
NSString * const NotificationActionDecline = @"com.vialer.notification.decline";
NSString * const NotificationActionAccept = @"com.vialer.notification.accept";

@interface ConnectionHandler ()
@property (nonatomic, assign) BOOL isOnWiFi;
@property (nonatomic, assign) BOOL isOn4G;
@property (nonatomic, strong) GSAccountConfiguration *account;
@property (nonatomic, strong) GSConfiguration *config;
@property (nonatomic, strong) GSUserAgent *userAgent;
@end

@implementation ConnectionHandler

static GSCall *lastNotifiedCall;

+ (ConnectionHandler *)sharedConnectionHandler {
    static dispatch_once_t pred;
    static ConnectionHandler *_sharedConnectionHandler = nil;

    dispatch_once(&pred, ^{
        _sharedConnectionHandler = [[self alloc] init];
    });
    return _sharedConnectionHandler;
}

- (id)init {
    self = [super init];
    if (self != nil) {
        pj_activesock_enable_iphone_os_bg(PJ_TRUE);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)connectionStatusChanged {
    [self sipUpdateConnectionStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:ConnectionStatusChangedNotification object:self];
}

- (ConnectionStatus)connectionStatus {
    ConnectionStatus newConnectionStatus = (self.isOn4G || self.isOnWiFi) ? ConnectionStatusHigh : ConnectionStatusLow;
    NSLog(@"Connection Status changed to: %@", [self connectionStatusToString:newConnectionStatus]);
    return newConnectionStatus;
}

- (NSString *)connectionStatusToString:(ConnectionStatus)connectionStatus {
    NSString *humanReadableConnectionStatusString;
    switch (connectionStatus) {
        case ConnectionStatusHigh:
            humanReadableConnectionStatusString = @"ConnectionStatusHigh";
            break;
            
        case ConnectionStatusLow:
            humanReadableConnectionStatusString = @"ConnectionStatusLow";
            break;
            
        default:
            humanReadableConnectionStatusString = [NSString stringWithFormat:@"Unknown ConnectionStatus(%u)",connectionStatus];
            break;
    }
    return humanReadableConnectionStatusString;
}

- (GSAccountStatus)accountStatus {
    GSAccount *account = [GSUserAgent sharedAgent].account;
    GSAccountStatus status = GSAccountStatusOffline; //GSAccountStatusInvalid;
    if (account)
        status = account.status;
    
    NSLog(@"GS Account Status changed to: %@", [self gsAccountStatusToString:status]);
    return status;
}

- (NSString *)gsAccountStatusToString:(GSAccountStatus)accountStatus {
    NSString *humanReadableStatusString;
    
    switch (accountStatus) {
        case GSAccountStatusOffline: ///< Account is offline or no registration has been done.
            humanReadableStatusString = @"GSAccountStatusOffline";
            break;
        case GSAccountStatusInvalid: ///< Gossip has attempted registration but the credentials were invalid.
            humanReadableStatusString = @"GSAccountStatusInvalid";
            break;
        case GSAccountStatusConnecting: ///< Gossip is trying to register the account with the SIP server.
            humanReadableStatusString = @"GSAccountStatusConnecting";
            break;
        case GSAccountStatusConnected: ///< Account has been successfully registered with the SIP server.
            humanReadableStatusString = @"GSAccountStatusConnected";
            break;
        case GSAccountStatusDisconnecting: ///< Account is being unregistered from the SIP server.
            humanReadableStatusString = @"GSAccountStatusDisconnecting";
            break;
            
        default:
            humanReadableStatusString = [NSString stringWithFormat:@"Unknown GSAccountStatus (%u)", accountStatus];
            break;
    }
    
    return humanReadableStatusString;
}

- (void)start {
    // Check if radio access is at least 4G
    __block NSString *highNetworkTechnology = CTRadioAccessTechnologyLTE; // 4G
//    __block NSString *highNetworkTechnology = CTRadioAccessTechnologyWCDMA; // 3G

    CTTelephonyNetworkInfo *telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
    self.isOn4G = [telephonyInfo.currentRadioAccessTechnology isEqualToString:highNetworkTechnology];
    [[NSNotificationCenter defaultCenter] addObserverForName:CTRadioAccessTechnologyDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *notification) {
        BOOL isOn4G = [notification.object isEqualToString:highNetworkTechnology];
        if (self.isOn4G != isOn4G) {
            self.isOn4G = isOn4G;
            [self connectionStatusChanged];
        }
    }];

    // Check WiFi or no WiFi
    self.isOnWiFi = [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        BOOL isOnWiFi = (status == AFNetworkReachabilityStatusReachableViaWiFi);
        if (self.isOnWiFi != isOnWiFi) {
            self.isOnWiFi = isOnWiFi;
            [self connectionStatusChanged];
        }
    }];
}

- (void)sipConnect {
    [self sipDisconnect:^{
        NSString *sipAccount = [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] sipAccount];
        NSString *sipPassword = [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] sipPassword];
        if (!sipAccount || !sipPassword) {
            return;
        }

        if (!self.account) {
            self.account = [GSAccountConfiguration defaultConfiguration];
            self.account.domain = self.sipDomain;
            self.account.username = sipAccount;
            self.account.password = sipPassword;
            self.account.address = [self.account.username stringByAppendingFormat:@"@%@", self.account.domain];
            self.account.proxyServer = [self.account.domain stringByAppendingString:@";transport=tcp"];
            self.account.enableRingback = NO;
        }

        if (!self.config) {
            self.config = [GSConfiguration defaultConfiguration];
            self.config.account = self.account;
            self.config.logLevel = 3;
            self.config.consoleLogLevel = 3;
            self.config.transportType = GSTCPTransportType;
        }

        if (!self.userAgent) {
            self.userAgent = [GSUserAgent sharedAgent];

            [self.userAgent configure:self.config withEchoCancellation:200];
            [self.userAgent start];

            [self.userAgent.account addObserver:self
                                     forKeyPath:@"status"
                                        options:NSKeyValueObservingOptionInitial
                                        context:nil];
        }

        self.userAgent.account.delegate = self;

        if (self.userAgent.account.status == GSAccountStatusOffline) {
            [self.userAgent.account connect];
        }
    }];
}

- (void)sipDisconnect:(void (^)())finished {
    BOOL connected = (self.userAgent.account.status == GSAccountStatusConnected);
    if (connected) {
        [self.userAgent.account disconnect:finished];
    }

    self.userAgent.account.delegate = nil;
    [self.userAgent.account removeObserver:self forKeyPath:@"status"];
    [self.userAgent reset];

    self.userAgent = nil;
    self.account = nil;
    self.config = nil;

    if (!connected && finished) {
        finished();
    }
}

- (void)sipUpdateConnectionStatus {
    if (self.connectionStatus == ConnectionStatusHigh) {
        // Only connect if we're not already connect(ed/ing)
        if (self.accountStatus != GSAccountStatusConnected && self.accountStatus != GSAccountStatusConnecting) {
            NSLog(@"High traffic network: Connect SIP");
            [self sipConnect];
        }
    } else if ([[GSCall activeCalls] count] == 0) {
        // Only disconnect if no active calls are being made
        NSLog(@"Low traffic network: Disconnect SIP");
        [self sipDisconnect:nil];
    }
}

- (NSString *)sipDomain {
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
    NSAssert(config != nil, @"Config.plist not found!");

    NSString *sipDomain = [[config objectForKey:@"URLS"] objectForKey:@"SIP domain"];
    NSAssert(sipDomain != nil, @"URLS - SIP domain not found in Config.plist!");

    return sipDomain;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        if ([object isKindOfClass:[GSAccount class]]) {
            [self accountStatusDidChange:object];
        } else {
            [self callStatusDidChange];
        }
    }
}

- (void)accountStatusDidChange:(GSAccount *)account {
    switch (account.status) {
        case GSAccountStatusOffline: {
        } break;

        case GSAccountStatusInvalid: {
        } break;

        case GSAccountStatusConnecting: {
        } break;

        case GSAccountStatusConnected: {
            [self setCodecs];
            [self connectionStatusChanged];
        } break;

        case GSAccountStatusDisconnecting: {
        } break;
    }
}

- (void)callStatusDidChange {
    if (lastNotifiedCall.status == GSCallStatusDisconnected) {
        [self clearLastNotifiedCall];
    }
}

- (void)setCodecs {
    if (self.userAgent.status >= GSUserAgentStateConfigured) {
        NSArray *codecs = [self.userAgent arrayOfAvailableCodecs];
        for (GSCodecInfo *codec in codecs) {
            if ([codec.codecId isEqual:@"PCMA/8000/1"]) {
                [codec setPriority:254];
            }
        }
    }
}

#pragma mark - Notifications

- (void)didBecomeActiveNotification:(NSNotification *)notification {
    if (lastNotifiedCall) {
        AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
        [appDelegate handleSipCall:lastNotifiedCall];
    }
    [self clearLastNotifiedCall];
}

- (void)handleLocalNotification:(UILocalNotification *)notification withActionIdentifier:(NSString *)identifier {
    if (lastNotifiedCall) {
        NSDictionary *userInfo = notification.userInfo;
        NSNumber *callId = [userInfo objectForKey:@"callId"];
        if ([callId isKindOfClass:[NSNumber class]] && lastNotifiedCall.callId == [callId intValue] && lastNotifiedCall.status != GSCallStatusDisconnected) {
            if ([identifier isEqualToString:NotificationActionDecline]) {
                [lastNotifiedCall end];
            } else {
                AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
                [appDelegate handleSipCall:lastNotifiedCall];
            }
        }

        [self clearLastNotifiedCall];
    }
}

- (void)registerForLocalNotifications {
    UIApplication *application = [UIApplication sharedApplication];

    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIMutableUserNotificationAction *declineAction = [[UIMutableUserNotificationAction alloc] init];
        [declineAction setActivationMode:UIUserNotificationActivationModeBackground];
        [declineAction setTitle:NSLocalizedString(@"Decline", nil)];
        [declineAction setIdentifier:NotificationActionDecline];

        UIMutableUserNotificationAction *acceptAction = [[UIMutableUserNotificationAction alloc] init];
        [acceptAction setActivationMode:UIUserNotificationActivationModeForeground];
        [acceptAction setTitle:NSLocalizedString(@"Accept", nil)];
        [acceptAction setIdentifier:NotificationActionAccept];

        UIMutableUserNotificationCategory *actionCategory = [[UIMutableUserNotificationCategory alloc] init];
        [actionCategory setIdentifier:NotificationAcceptDeclineCategory];
        [actionCategory setActions:@[acceptAction, declineAction]
                        forContext:UIUserNotificationActionContextDefault];

        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge)
                                                                                 categories:[NSSet setWithObject:actionCategory]];
        [application registerUserNotificationSettings:settings];
    } else {
        [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    }
}

- (void)clearLastNotifiedCall {
    [lastNotifiedCall removeObserver:self forKeyPath:@"status"];
    lastNotifiedCall = nil;
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

+ (void)showLocalNotificationForIncomingCall:(GSCall *)incomingCall {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"Incoming call from %@", nil), incomingCall.remoteInfo];
    notification.soundName = @"incoming.caf";
    notification.userInfo = @{@"callId":@(incomingCall.callId)};

    if ([notification respondsToSelector:@selector(setCategory:)]) {
        notification.category = NotificationAcceptDeclineCategory;
    }

    lastNotifiedCall = incomingCall;

    [lastNotifiedCall addObserver:[ConnectionHandler sharedConnectionHandler]
                       forKeyPath:@"status"
                          options:NSKeyValueObservingOptionInitial
                          context:nil];

    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

#pragma mark - GSAccount delegate

- (void)account:(GSAccount *)account didReceiveIncomingCall:(GSCall *)call {
    NSLog(@"Received incoming call");
    [[NSNotificationCenter defaultCenter] postNotificationName:IncomingSIPCallNotification object:call];
}

@end
