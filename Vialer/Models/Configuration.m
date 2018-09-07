//
//  Configuration.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "Configuration.h"

NSString * const ConfigurationGADimensionClientIDIndex = @"Client ID index";
NSString * const ConfigurationGADimensionBuildIndex = @"Build index";

static NSString * const ConfigurationColorsKey = @"Tint colors";
static NSString * const ConfigurationGACustomDimensionKey = @"GA Custom Dimensions";
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

@end
