//
//  LoginFormView.m
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "LoginFormView.h"
#import "UIView+RoundedStyle.h"
#import "Vialer-Swift.h"

static CGFloat const LoginFormViewButtonRadius = 5.0;

@interface LoginFormView ()
//Display's "Business"
@property (nonatomic, weak) IBOutlet UILabel *businessLabel;
//Display's "calls in the cloud"
@property (nonatomic, weak) IBOutlet UILabel *callsInTheCloudLabel;
@end

@implementation LoginFormView

- (void)awakeFromNib {
    [super awakeFromNib];
    //Localize elements of view
    self.businessLabel.text = NSLocalizedString(@"Business", nil);
    self.callsInTheCloudLabel.text = NSLocalizedString(@"calls in the cloud", nil);

    self.usernameField.placeholder = NSLocalizedString(@"Email address", nil);
    self.passwordField.placeholder = NSLocalizedString(@"Password", nil);

    [self.usernameField cleanStyle];
    [self.passwordField cleanStyle];

    [self.loginButton setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
    [self.forgotPasswordButton setTitle:NSLocalizedString(@"Forgot password?", nil) forState:UIControlStateNormal];
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    [self.configurationInstructionsButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"How does %@ work?", nil), appName] forState:UIControlStateNormal];

    self.isMoved = NO;

    [self setupRoundedButtons:@[self.loginButton, self.forgotPasswordButton, self.configurationInstructionsButton]];
}

- (void)setupRoundedButtons:(NSArray<RoundedAndColoredUIButton *> *)buttons {
    for (RoundedAndColoredUIButton *button in buttons) {
        button.borderWidth = 1;
        button.cornerRadius = LoginFormViewButtonRadius;
        button.borderColor = [[ColorsConfiguration shared] colorForKey:ColorsLogInViewControllerButtonBorder];
        button.backgroundColorForPressedState = [[ColorsConfiguration shared]  colorForKey: ColorsLogInViewControllerButtonBackgroundPressedState];
    }
}

- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)delegate {
    self.passwordField.delegate = delegate;
    self.usernameField.delegate = delegate;
}

@end
