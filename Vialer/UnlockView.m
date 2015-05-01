//
//  UnlockView.m
//  Vialer
//
//  Created by Karsten Westra on 29/04/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "UnlockView.h"

@implementation UnlockView

- (void)setupSlider {
    [_slideToUnlock setThumbImage: [UIImage imageNamed:@"slider-button.png"] forState:UIControlStateNormal];
    [_slideToUnlock setMinimumTrackImage:[UIImage new] forState:UIControlStateNormal]; // preventthe bar to be shown
    [_slideToUnlock setMaximumTrackImage:[UIImage new] forState:UIControlStateNormal]; // preventthe bar to be shown
}

@end
