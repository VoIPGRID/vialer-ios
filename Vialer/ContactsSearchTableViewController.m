//
//  ContactsSearchTableViewController.m
//  Vialer
//
//  Created by Johannes Nevels on 23-04-15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "ContactsSearchTableViewController.h"
#import "ContactTableViewCell.h"

@interface ContactsSearchTableViewController ()

@end

@implementation ContactsSearchTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.searchResults.count == 0) {
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    } else{
        tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }

    // Return the number of rows in the section.
    //NSLog(@"%s: ResultCount -> %ld", __PRETTY_FUNCTION__, (unsigned long)_searchResults.count);
    return self.searchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"cellForRowAtIndexPath");
    ContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddressBookContactCellIdentifier"];
    if (cell == nil) {
        cell = [[ContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AddressBookContactCellIdentifier"];
    }
    
    NSDictionary *contact = [self.searchResults objectAtIndex:indexPath.row];
    [cell populateBasedOnContactDict:contact];
    
    return cell;
}

@end
