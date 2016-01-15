//
//  VialerWebViewController.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "Configuration.h"

#import <PBWebViewController/PBWebViewController.h>

@interface VialerWebViewController : PBWebViewController

@property (strong, nonatomic) NSString *nextUrl;
@property (nonatomic) Configuration *configuration;

@end
