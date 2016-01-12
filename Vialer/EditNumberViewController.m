//
//  EditNumberViewController.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "EditNumberViewController.h"

#import "GAITracker.h"
#import "SVProgressHUD.h"
#import "VoIPGRIDRequestOperationManager.h"

@interface EditNumberViewController ()
@property (weak, nonatomic) IBOutlet UITextField *numberTextField;
@end

@implementation EditNumberViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GAITracker trackScreenForControllerName:NSStringFromClass([self class])];
    self.numberTextField.text = self.numberToEdit;
    [self.numberTextField becomeFirstResponder];
}

#pragma mark - Properties

- (void)setNumberToEdit:(NSString *)numberToEdit {
    _numberToEdit = numberToEdit;
    self.numberTextField.text = numberToEdit;
}

#pragma mark - Actions

- (IBAction)backButtonPressed:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveButtonPressed:(UIBarButtonItem *)sender {
    NSString *newNumber = self.numberTextField.text;
    [SVProgressHUD showWithStatus:NSLocalizedString(@"SAVING_NUMBER...", nil) maskType:SVProgressHUDMaskTypeGradient];

    [[VoIPGRIDRequestOperationManager sharedRequestOperationManager] pushMobileNumber:newNumber forcePush:NO success:^{
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"NUMBER_SAVED_SUCCESS", nil)];
        [self.delegate numberHasChanged:newNumber];
        [self.navigationController popViewControllerAnimated:YES];

    } failure:^(NSString *localizedErrorString) {
        [SVProgressHUD dismiss];
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                              message:localizedErrorString
                                              preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];

        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }];
}

@end
