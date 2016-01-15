//
//  VialerDrawerViewController.m
//  Vialer
//
//  Created by Bob Voorneveld on 17/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "VialerDrawerViewController.h"

static float const VialerRootViewControllerMaximunDrawerWidth = 280.0f;
static float const VialerRootViewControllerShadowRadius = 2.0f;
static float const VialerRootViewControllerShadowOpacity = 0.5f;
static NSString * const VialerDrawerViewControllerTabBarIdentifier = @"TabBarIdentifier";
static NSString * const VialerDrawerViewControllerMenuIdentifier = @"MenuIdentifier";

@implementation VialerDrawerViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.restorationIdentifier = @"MMDrawer";
        self.maximumLeftDrawerWidth = VialerRootViewControllerMaximunDrawerWidth;
        self.openDrawerGestureModeMask = MMOpenDrawerGestureModeAll;
        self.closeDrawerGestureModeMask = MMCloseDrawerGestureModeAll;
        self.shadowRadius = VialerRootViewControllerShadowRadius;
        self.shadowOpacity = VialerRootViewControllerShadowOpacity;
    }
    return self;
}

@end
