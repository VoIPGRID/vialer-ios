//
//  TrackedViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 20/03/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "TrackedViewController.h"

@interface TrackedViewController ()

@end

@implementation TrackedViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.screenName = [NSStringFromClass([self class]) stringByReplacingOccurrencesOfString:@"ViewController" withString:@""];
}

@end
