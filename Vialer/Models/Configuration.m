//
//  Configuration.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "Configuration.h"

/** Key definition for Config file */
NSString * const ConfigurationVoIPGRIDBaseURLString = @"API";
NSString * const ConfigurationMiddleWareBaseURLString = @"Middelware BaseLink";
NSString * const ConfigurationSIPDomain = @"SIP domain";
NSString * const ConfigurationPartnerURLKey = @"Partner";

NSString * const ConfigurationGADimensionClientIDIndex = @"Client ID index";
NSString * const ConfigurationGADimensionBuildIndex = @"Build index";

static NSString * const ConfigurationColorsKey = @"Tint colors";
static NSString * const ConfigurationUrlsKey = @"URLS";
static NSString * const ConfigurationGACustomDimensionKey = @"GA Custom Dimensions";
static NSString * const ConfigurationLogEntriesToken = @"LogEntries Token";

@interface Configuration ()
@property (strong, nonatomic) NSDictionary *configPlist;
@property (strong, nonatomic) ColorConfiguration *colorConfiguration;
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

- (NSString *)logEntriesToken {
    return self.configPlist[ConfigurationLogEntriesToken];
}

@end
