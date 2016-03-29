//
//  EditNumberViewController.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import "EditNumberViewController.h"

#import "GAITracker.h"
#import "SVProgressHUD.h"
#import "SystemUser.h"
#import "UIAlertController+Vialer.h"
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
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Saving number...", nil)];

    [[SystemUser currentUser] updateMobileNumber:newNumber withCompletion:^(BOOL success, NSError *error) {
        [SVProgressHUD dismiss];
        if (success) {
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Number saved", nil)];
            [self.delegate numberHasChanged:newNumber];
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error saving number", nil) message:error.localizedDescription andDefaultButtonText:NSLocalizedString(@"Ok", nil)];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

@end
