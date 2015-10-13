//
//  Configuration.m
//  Vialer
//
//  Created by Maarten de Zwart on 11/09/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "Configuration.h"

/** Key definition for Config file */
NSString * const kTintColorTabBar = @"TabBar";
NSString * const kTintColorNavigationBar = @"NavigationBar";
NSString * const kTintColorTable = @"Table";
NSString * const kBarTintColorSearchBar = @"SearchBarBar";
NSString * const kTintColorSearchBar = @"SearchBar";
NSString * const kTintColorMessage = @"Message";

NSString * const kTintColorsKey = @"Tint colors";
NSString * const kUrlsKey = @"URLS";

@interface Configuration ()

@property (nonatomic, strong) NSDictionary *dictionary;

@end

@implementation Configuration

#pragma mark - Initialization methods

- (instancetype)init {
    self = [super init];
    if (self) {
        // Always read the Config.plist from the main bundle
        self.dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
        NSAssert(self.dictionary != nil, @"Config.plist not found!");
        
        if (self.dictionary == nil) {
            self.dictionary = [NSDictionary dictionary];
        }
    }
    return self;
}

#pragma mark - Public instance methods

- (UIColor *)tintColorForKey:(NSString *)key {
    NSDictionary *colors = [self.dictionary objectForKey:kTintColorsKey];
    NSArray *color = [colors objectForKey:key];
    NSAssert(color != nil && color.count == 3, @"%@ - %@ not found in Config.plist!", kTintColorsKey, key);
    return [UIColor colorWithRed:[color[0] intValue] / 255.f green:[color[1] intValue] / 255.f blue:[color[2] intValue] / 255.f alpha:1.f];
}

- (NSString *)UrlForKey:(NSString *)key {
    NSDictionary *URLS = [self.dictionary objectForKey:kUrlsKey];
    NSString *urlString = [URLS objectForKey:key];
    NSAssert(urlString != nil, @"%@ - %@, not found in Config.plist!", kUrlsKey, key);
    return urlString;
}

- (id)objectInConfigKeyed:(NSString *)firstKey, ... {
    id object = self.dictionary;
    va_list args;
    va_start(args, firstKey);
    for (NSString *key = firstKey; key != nil; key = va_arg(args, NSString*)) {
        if ([object isKindOfClass:[NSDictionary class]]) {
            object = [(NSDictionary *)object objectForKey:key];
        } else {
            NSLog(@"%@ is not avaialable in a Dictionary", key);
            object = nil;
        }
    }
    va_end(args);
    
    return object;
}

#pragma mark - Public static methods

+ (UIColor *)tintColorForKey:(NSString *)key {
    return [[Configuration new] tintColorForKey:key];
}

+ (NSString *)UrlForKey:(NSString *)key {
    return [[Configuration new] UrlForKey:key];
}

@end
