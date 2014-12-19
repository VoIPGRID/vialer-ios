//
//  SIPCallingViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 15/12/14.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "SIPCallingViewController.h"

#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

@interface SIPCallingViewController ()
@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) NSArray *subTitles;
@end

@implementation SIPCallingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.images = @[@"numbers-button", @"pause-button", @"mute-button", @"", @"speaker-button", @""];
    self.subTitles = @[NSLocalizedString(@"numbers", nil), NSLocalizedString(@"pause", nil), NSLocalizedString(@"sound off", nil), @"", NSLocalizedString(@"speaker", nil), @""];

    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);

    CGFloat buttonXSpace = self.view.frame.size.width / 3.4f;
    CGFloat leftOffset = (self.view.frame.size.width - (3.f * buttonXSpace)) / 2.f;
    self.contactLabel.frame = CGRectMake(leftOffset, self.contactLabel.frame.origin.y, self.view.frame.size.width - (leftOffset * 2.f), self.contactLabel.frame.size.height);
    self.statusLabel.frame = CGRectMake(leftOffset, self.statusLabel.frame.origin.y, self.view.frame.size.width - (leftOffset * 2.f), self.statusLabel.frame.size.height);

    [self addButtonsToView:self.buttonsView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

//    CGRect frame = [UIScreen mainScreen].bounds;
//    frame.size.height -= 49.f;
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0f) {
//        frame.origin.y -= 20.0f;
//    }
//    self.view.frame = frame;
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addButtonsToView:(UIView *)view {
    CGFloat buttonXSpace = self.view.frame.size.width / 3.4f;
    CGFloat buttonYSpace = self.view.frame.size.width / 3.f;
    CGFloat leftOffset = (view.frame.size.width - (3.f * buttonXSpace)) / 2.f;

    CGPoint offset = CGPointMake(0, 0);
    for (int j = 0; j < 2; j++) {
        offset.x = leftOffset;
        for (int i = 0; i < 3; i++) {
            NSString *image = self.images[j * 3 + i];
            if ([image length] != 0) {
                NSString *subTitle = self.subTitles[j * 3 + i];
                UIButton *button = [self createDialerButtonWithImage:image andSubTitle:subTitle];
                [button addTarget:self action:@selector(callButtonPressed:) forControlEvents:UIControlEventTouchDown];
                button.tag = j * 3 + i;

                button.frame = CGRectMake(offset.x, offset.y, buttonXSpace, buttonXSpace);
                [view addSubview:button];
            }

            offset.x += buttonXSpace;
        }
        offset.y += buttonYSpace;
    }

    view.frame = CGRectMake(view.frame.origin.x, (self.view.frame.size.height + 49.f - offset.y) / 2.f, view.frame.size.width, view.frame.size.height);
}

- (UIButton *)createDialerButtonWithImage:(NSString *)image andSubTitle:(NSString *)subTitle {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:[image stringByAppendingString:@"-highlighted"]] forState:UIControlStateHighlighted];
    [button setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
    [button setTitle:subTitle forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:14.f];

    // Center the image and title
    CGFloat spacing = 4.0;
    CGSize imageSize = button.imageView.image.size;
    button.titleEdgeInsets = UIEdgeInsetsMake(0.0, -imageSize.width, -(imageSize.height + spacing), 0.0);
    CGSize titleSize = [button.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:button.titleLabel.font}];
    button.imageEdgeInsets = UIEdgeInsetsMake(-(titleSize.height + spacing), 0.0, 0.0, -titleSize.width);
    return button;
}

- (void)handlePhoneNumber:(NSString *)phoneNumber forContact:(NSString *)contact {
    if (!self.presentingViewController) {
        [[[[UIApplication sharedApplication] delegate] window].rootViewController presentViewController:self animated:YES completion:nil];
    }
}

- (void)callButtonPressed:(UIButton *)sender {

}

- (IBAction)hangupButtonPressed:(UIButton *)sender {
    [self dismiss];
}

@end
