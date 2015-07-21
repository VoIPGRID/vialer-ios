//
//  EditNumberTableViewController.m
//  Vialer
//
//  Created by Harold on 22/06/15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "EditNumberTableViewController.h"
#import "CellWithTextField.h"

#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@implementation EditNumberTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"My number", nil);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed)];
    [self.tableView registerNib:[UINib nibWithNibName:@"CellWithTextField" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"CellWithTextField"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:[NSStringFromClass([self class]) stringByReplacingOccurrencesOfString:@"ViewController" withString:@""]];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

- (void)saveButtonPressed {
    [self.delegate numberHasChanged:self.numberTextFieldCell.textField.text];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CellWithTextField *cell = [tableView dequeueReusableCellWithIdentifier:@"CellWithTextField"];
    if (!cell)
        cell = [[CellWithTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellWithTextField"];

    cell.textField.delegate = self;
    cell.textField.text = self.numberToEdit;
    [cell.textField becomeFirstResponder];
    
    return cell;
}

- (CellWithTextField *)numberTextFieldCell {
    return (CellWithTextField *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

@end
