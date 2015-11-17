//
//  SideMenuTableViewController.m
//  Vialer
//
//  Created by Bob Voorneveld on 17/11/15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "SideMenuViewController.h"

#import "Configuration.h"
#import "SystemUser.h"

@interface SideMenuViewController ()

@property (strong, nonatomic) UIColor *tintColor;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *outgoingNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *buildVersionLabel;

@property (strong, nonatomic) NSString *appVersionBuildString;

@end

@implementation SideMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    self.usernameLabel.text = [SystemUser currentUser].displayName;
    self.outgoingNumberLabel.text = [SystemUser currentUser].outgoingNumber;
}
- (void)setupLayout {

}

#pragma mark - properties

- (UIColor *)tintColor {
    return [Configuration tintColorForKey:ConfigurationSideMenuTintColor];
}

- (void)setUsernameLabel:(UILabel *)usernameLabel {
    _usernameLabel = usernameLabel;
    _usernameLabel.textColor = [Configuration tintColorForKey:ConfigurationSideMenuTintColor];
}

- (void)setOutgoingNumberLabel:(UILabel *)outgoingNumberLabel {
    _outgoingNumberLabel = outgoingNumberLabel;
    _outgoingNumberLabel.textColor = [Configuration tintColorForKey:ConfigurationSideMenuTintColor];
}

- (void)setBuildVersionLabel:(UILabel *)buildVersionLabel {
    _buildVersionLabel = buildVersionLabel;
    _buildVersionLabel.text = self.appVersionBuildString;

}

#pragma mark - utils

- (NSString *)appVersionBuildString {
    if (!_appVersionBuildString) {
        NSDictionary *infoDict = [NSBundle mainBundle].infoDictionary;
        NSMutableString *versionString = [NSMutableString stringWithFormat:@"v:%@", [infoDict objectForKey:@"CFBundleShortVersionString"]];
        //We sometimes use a tag the likes of 2.0.beta.03. Since Apple only wants numbers and dots as CFBundleShortVersionString
        //the additional part of the tag is stored in de plist by the update_version_number script. If set, display
        NSString *additionalVersionString = [infoDict objectForKey:@"Additional_Version_String"];
        if ([additionalVersionString length] >0)
            [versionString appendFormat:@".%@", additionalVersionString];
        NSString *version = [NSString stringWithFormat:@"%@ (%@)",
                             versionString,
                             [infoDict objectForKey:@"CFBundleVersion"]];

#if DEBUG
        version = [NSString stringWithFormat:@"%@ (%@) | %@",
                   versionString,
                   [infoDict objectForKey:@"CFBundleVersion"],
                   [infoDict objectForKey:@"Commit_Short_Hash"]];
#endif
        _appVersionBuildString = version;
    }
    return _appVersionBuildString;
}

@end
