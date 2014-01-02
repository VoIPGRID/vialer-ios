//
//  SelectRecentsFilterViewController.h
//  Vialer
//
//  Created by Reinier Wieringa on 18/12/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import "SelectRecentsFilterViewController.h"

@interface SelectRecentsFilterViewController ()
@property (nonatomic, strong) NSArray *recents;
@end

@implementation SelectRecentsFilterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = NSLocalizedString(@"Show recents", nil);
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonPressed:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStyleDone target:self action:@selector(saveButtonPressed:)];

    self.recents = @[NSLocalizedString(@"Show your recent calls", nil), NSLocalizedString(@"Show all recent calls", nil)];
    [self.pickerView selectRow:self.recentsFilter inComponent:0 animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setPickerView:nil];
    [super viewDidUnload];
}

#pragma mark - PickerView DataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.recents.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.recents objectAtIndex:row];
}

#pragma mark - PickerView Delegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
}

#pragma mark - Actions

- (void)cancelButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)saveButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(selectRecentsFilterViewController:didFinishWithRecentsFilter:)]) {
        [self.delegate selectRecentsFilterViewController:self didFinishWithRecentsFilter:(RecentsFilter)[self.pickerView selectedRowInComponent:0]];
    }
    [self dismissViewControllerAnimated:YES completion:^{}];
}

@end
