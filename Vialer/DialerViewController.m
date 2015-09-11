//
//  DialerViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 15/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "DialerViewController.h"
#import "AppDelegate.h"
#import "ConnectionHandler.h"
#import "AnimatedNumberPadViewController.h"
#import "SIPCallingViewController.h"
#import "UIViewController+MMDrawerController.h"
#import "VoIPGRIDRequestOperationManager.h"

#import "AFNetworkReachabilityManager.h"

#import <AudioToolbox/AudioServices.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCall.h>

#import "Reachability.h"

@interface DialerViewController ()
@property (nonatomic, strong) CTCallCenter *callCenter;
@property (nonatomic, strong) AnimatedNumberPadViewController *numberPadViewController;
@property (nonatomic, strong) Reachability *reachabilityManager;
@end

@implementation DialerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Keypad", nil);
        self.tabBarItem.image = [UIImage imageNamed:@"tab-keypad"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"tab-keypad-active"];
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
        
        // Add hamburger menu on navigation bar
        UIBarButtonItem *leftDrawerButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"] style:UIBarButtonItemStyleBordered target:self action:@selector(leftDrawerButtonPress:)];
        leftDrawerButton.tintColor = [UIColor colorWithRed:(145.f / 255.f) green:(145.f / 255.f) blue:(145.f / 255.f) alpha:1.f];
        self.navigationItem.leftBarButtonItem = leftDrawerButton;

        __weak typeof(self) weakSelf = self;
        self.callCenter = [[CTCallCenter alloc] init];
        [self.callCenter setCallEventHandler:^(CTCall *call) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.backButton.hidden = YES;
                weakSelf.callButton.enabled = NO;
                weakSelf.numberTextView.text = @"";
            });
            NSLog(@"callEventHandler2: %@", call.callState);
        }];
        
        [self.reachabilityManager startNotifier];
    }
    return self;
}

-(void)dealloc {
    [self.reachabilityManager stopNotifier];
}

- (Reachability *)reachabilityManager{
    if (!_reachabilityManager) {
        _reachabilityManager = [Reachability reachabilityForInternetConnection];
        // Set the blocks
        __weak typeof(self) weakSelf = self;
        _reachabilityManager.reachableBlock = ^(Reachability*reach) {
            // keep in mind this is called on a background thread
            // and if you are updating the UI it needs to happen
            // on the main thread, like this:
            dispatch_async(dispatch_get_main_queue(), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"REACHABLE!");
                    [weakSelf connectionStatusChangedNotification:nil];
                });
            });
        };
        
        _reachabilityManager.unreachableBlock = ^(Reachability*reach) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"UNREACHABLE!");
                [weakSelf connectionStatusChangedNotification:nil];
            });
        };
    }
    return _reachabilityManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //TODO: what about de-registering for these notifications in, for instance, -viewDidUnload
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionStatusChangedNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionStatusChangedNotification:) name:ConnectionStatusChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sipCallStartedNotification:) name:SIPCallStartedNotification object:nil];

    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.width);

    self.numberPadViewController = [[AnimatedNumberPadViewController alloc] init];
    self.numberPadViewController.view.frame = self.buttonsView.bounds;
    [self.buttonsView addSubview:self.numberPadViewController.view];
    [self addChildViewController:self.numberPadViewController];
    self.numberPadViewController.delegate = self;
    self.numberPadViewController.tonesEnabled = YES;

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(backButtonLongPress:)];
    [self.backButton addGestureRecognizer:longPress];
    
    self.backButton.hidden = YES;
    self.callButton.enabled = NO;

    [self connectionStatusChangedNotification:nil];
    
    // Color the warning
    self.statusView.backgroundColor = [Configuration tintColorForKey:kTintColorMessage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//We need a way to distinquish between
// - no internet at all
// - internet below wifi/4g -> connect A/B only
// - A user who has no Mobile app VoIP account
- (void)connectionStatusChangedNotification:(NSNotification *)notification {
    //Function is called when inet connection is interrupted... but not always
    
    if ([self.reachabilityManager isReachable]) {
    //we have internets!!
        self.buttonsView.userInteractionEnabled = self.backButton.userInteractionEnabled = self.numberTextView.userInteractionEnabled = YES;
        self.callButton.enabled = YES;
        
        //does the user have a sip account?
        if ([VoIPGRIDRequestOperationManager sharedRequestOperationManager].sipAccount) {
            //Is the connection quality sufficient for SIP?
            if ([ConnectionHandler sharedConnectionHandler].connectionStatus == ConnectionStatusHigh) {
                [self hideMessage];
            } else {
                
                [self showMessage:NSLocalizedString(@"Poor internet connection Connect A/B", nil) withInfo:NSLocalizedString(@"Poor internet Info", nil)];
            }
        } else {
            [self showMessage:NSLocalizedString(@"Connect A/B calls only", nil) withInfo:NSLocalizedString(@"Connect A/B Info", nil)];
        }
    } else {
        self.buttonsView.userInteractionEnabled = self.backButton.userInteractionEnabled = self.numberTextView.userInteractionEnabled = NO;
        self.callButton.enabled = NO;
        
        [self showMessage:NSLocalizedString(@"No Connection", nil) withInfo:NSLocalizedString(@"No Connection Info Text", nil)];
    }
    
//    NSLog(@"%s",__PRETTY_FUNCTION__);
//    GSAccountStatus status = [ConnectionHandler sharedConnectionHandler].accountStatus;
//    if (status == GSAccountStatusInvalid || status == GSAccountStatusOffline) {
//        self.buttonsView.userInteractionEnabled = self.backButton.userInteractionEnabled = self.numberTextView.userInteractionEnabled = NO;
//        self.callButton.enabled = NO;
//        
//        [self.statusLabel setHidden:NO];
//    } else {
//        self.buttonsView.userInteractionEnabled = self.backButton.userInteractionEnabled = self.numberTextView.userInteractionEnabled = YES;
//        self.callButton.enabled = [self.numberTextView.text length] > 0;
//        
//        [self.statusLabel setHidden:YES];
//    }
}

- (void)sipCallStartedNotification:(NSNotification *)notification {
    self.backButton.hidden = YES;
    self.callButton.enabled = NO;
    self.numberTextView.text = @"";
}

#pragma mark - TextView delegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *originalText = textView.text ? textView.text : @"";
    NSString *newString = [originalText stringByReplacingCharactersInRange:range withString:text];
    NSMutableCharacterSet *characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"0123456789+#*() "];
    if (newString.length != [[newString componentsSeparatedByCharactersInSet:[characterSet invertedSet]] componentsJoinedByString:@""].length) {
        return NO;
    }

    self.backButton.hidden = NO;
    self.callButton.enabled = YES;

    return YES;
}

#pragma mark - Actions
- (void)backButtonLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.numberTextView.text = @"";
        self.backButton.hidden = YES;
        self.callButton.enabled = NO;
    }
}

- (IBAction)dialerBackButtonPressed:(UIButton *)sender {
    if (self.numberTextView.text.length) {
        self.numberTextView.text = [self.numberTextView.text substringToIndex:self.numberTextView.text.length - 1];
    }
    self.backButton.hidden = (self.numberTextView.text.length == 0);
    self.callButton.enabled = (self.numberTextView.text.length > 0);
}

- (IBAction)callButtonPressed:(UIButton *)sender {
    NSString *phoneNumber = self.numberTextView.text;
    if (!phoneNumber.length) {
        return;
    }

    AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
    [appDelegate handlePhoneNumber:phoneNumber];
}

- (void)leftDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

#pragma mark - NumberPadViewController delegate

- (void)numberPadPressedWithCharacter:(NSString *)character {
    if (!self.numberTextView.text) {
        self.numberTextView.text = @"";
    }

    if ([character isEqualToString:@"+"] && self.numberTextView.text.length > 0) {
        self.numberTextView.text = [self.numberTextView.text substringToIndex:self.numberTextView.text.length - 1];
    }
    self.numberTextView.text = [self.numberTextView.text stringByAppendingString:character];

    self.backButton.hidden = NO;
    self.callButton.enabled = YES;
}

#pragma mark - Private status message handling

- (void)showMessage:(NSString *)message withInfo:(NSString *)info {
    self.infoMessage = info;
    self.statusLabel.text = message;
    self.statusView.hidden = NO;
    // Move the input a bit down
    [UIView animateWithDuration:0.1
                     animations:^{
                         self.numberTextView.frame = CGRectMake(self.numberTextView.frame.origin.x, 25.0,
                                                                self.numberTextView.frame.size.width, self.numberTextView.frame.size.height);
                         self.backButton.frame = CGRectMake(self.backButton.frame.origin.x, 25.0,
                                                            self.backButton.frame.size.width, self.backButton.frame.size.height);
                     }];
}

- (void)hideMessage {
    self.infoMessage = nil;
    // Hide the status label
    self.statusView.hidden = YES;
    // Position back the input fields
    [UIView animateWithDuration:0.1
                     animations:^{
                         self.numberTextView.frame = CGRectMake(self.numberTextView.frame.origin.x, 8.f,
                                                                self.numberTextView.frame.size.width, self.numberTextView.frame.size.height);
                         self.backButton.frame = CGRectMake(self.backButton.frame.origin.x, 8.f,
                                                            self.backButton.frame.size.width, self.backButton.frame.size.height);
                     }];

}

- (void)messageInfoPressed:(UIButton *)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.statusLabel.text
                                                    message:self.infoMessage
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    [alert show];
}

@end
