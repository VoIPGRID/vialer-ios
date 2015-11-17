//
//  VialerDrawerViewController.m
//  Vialer
//
//  Created by Bob Voorneveld on 17/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "VialerDrawerViewController.h"

static float const RootViewControllerMaximunDrawerWidth = 222.0;
static float const RootViewControllerShadowRadius = 2.0f;
static float const RootViewControllerShadowOpacity = 0.5f;
static NSString * const VialerDrawerViewControllerTabBarIdentifier = @"TabBarIdentifier";
static NSString * const VialerDrawerViewControllerMenuIdentifier = @"MenuIdentifier";

@interface VialerDrawerViewController ()

@end

@implementation VialerDrawerViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.restorationIdentifier = @"MMDrawer";
        self.maximumLeftDrawerWidth = RootViewControllerMaximunDrawerWidth;
        self.openDrawerGestureModeMask = MMOpenDrawerGestureModeAll;
        self.closeDrawerGestureModeMask = MMCloseDrawerGestureModeAll;
        self.shadowRadius = RootViewControllerShadowRadius;
        self.shadowOpacity = RootViewControllerShadowOpacity;
    }
    return self;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
