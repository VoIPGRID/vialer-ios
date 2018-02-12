//
//  Configuration.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "Configuration.h"

/** Key definition for Config file */
NSString * const ConfigurationVoIPGRIDBaseURLString = @"API";
NSString * const ConfigurationMiddleWareBaseURLString = @"Middelware BaseLink";
NSString * const ConfigurationSIPDomain = @"SIP domain";
NSString * const ConfigurationEncryptedSIPDomain = @"Encrypted SIP Domain";
NSString * const ConfigurationPartnerURLKey = @"Partner";

NSString * const ConfigurationGADimensionClientIDIndex = @"Client ID index";
NSString * const ConfigurationGADimensionBuildIndex = @"Build index";

static NSString * const ConfigurationColorsKey = @"Tint colors";
static NSString * const ConfigurationUrlsKey = @"URLS";
static NSString * const ConfigurationGACustomDimensionKey = @"GA Custom Dimensions";
static NSString * const ConfigurationLogEntries = @"Log Entries";
static NSString * const ConfigurationStunServers = @"Stun Servers";
static NSString * const ConfigurationLogEntriesMainToken = @"Main";
static NSString * const ConfigurationLogEntriesPartnerToken = @"Partner";
static NSString * const ConfigurationGoogleTrackingId = @"TRACKING_ID";

@interface Configuration ()
@property (strong, nonatomic) NSDictionary *configPlist;
@property (strong, nonatomic) ColorConfiguration *colorConfiguration;
@property (strong, nonatomic) NSDictionary *googleConfigPlist;
@end

@implementation Configuration

#pragma mark - Initialization methods

// To make the singleton pattern testable.
static Configuration *_defaultConfiguration = nil;
static dispatch_once_t onceToken = 0;

#pragma mark - Lifecycle
+ (instancetype)defaultConfiguration {
    dispatch_once(&onceToken, ^{
        _defaultConfiguration = [[self alloc] init];
    });
    return _defaultConfiguration;
}

+ (void)setDefaultConfiguration:(Configuration *)defaultConfiguration {
    if (_defaultConfiguration != defaultConfiguration) {
        _defaultConfiguration = defaultConfiguration;

        if (!_defaultConfiguration) {
            onceToken = 0;
        } else {
            onceToken = -1;
        }
    }
}

#pragma mark - Properties

- (NSDictionary *)configPlist {
    if (!_configPlist) {
        _configPlist = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
        NSAssert(_configPlist, @"Config.plist not found!");
    }
    return _configPlist;
}

- (NSDictionary *)googleConfigPlist {
    if (!_googleConfigPlist) {
        _googleConfigPlist = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"]];
        NSAssert(_googleConfigPlist, @"GoogleService-Info.plist not found!");
    }
    return _googleConfigPlist;
}

- (ColorConfiguration *)colorConfiguration {
    if (!_colorConfiguration) {
        _colorConfiguration = [[ColorConfiguration alloc] initWithConfigPlist:self.configPlist];
    }
    return _colorConfiguration;
}

#pragma mark - Public instance methods

- (NSString *)UrlForKey:(NSString *)key {
    NSString *urlString = self.configPlist[ConfigurationUrlsKey][key];
    NSAssert(urlString != nil, @"%@ - %@, not found in Config.plist!", ConfigurationUrlsKey, key);
    return urlString;
}

- (int)customDimensionIndexForKey:(NSString *)key {
    id value = self.configPlist[ConfigurationGACustomDimensionKey][key];
    NSAssert([value isKindOfClass:[NSNumber class]], @"Fetched key was not found or was not a NSNumber.");

    return ((NSNumber *)value).intValue;
}

- (NSDictionary *)logEntriesDictionairy {
    return self.configPlist[ConfigurationLogEntries];
}

- (NSString *)logEntriesToken {
    return [self logEntriesDictionairy][ConfigurationLogEntriesMainToken];
}

- (NSString *)logEntriesPartnerToken {
    return [self logEntriesDictionairy][ConfigurationLogEntriesPartnerToken];
}

- (NSString *)googleTrackingId {
    return self.googleConfigPlist[ConfigurationGoogleTrackingId];
}

- (NSArray<NSString *> *)stunServers {
    if (self.configPlist[ConfigurationUrlsKey][ConfigurationStunServers]) {
        return self.configPlist[ConfigurationUrlsKey][ConfigurationStunServers];
    }
    return [NSArray new];
}

@end
