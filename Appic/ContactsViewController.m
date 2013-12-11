//
//  ContactsViewController.m
//  Appic
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2013 Voys. All rights reserved.
//

#import "ContactsViewController.h"
#import "VoysRequestOperationManager.h"

#import "AppDelegate.h"

#define DASHBOARD_ALERT_TAG 100

@interface ContactsViewController()
@property (nonatomic, retain) id<UISearchDisplayDelegate> oldSearchDisplayDelegate;
@end

@implementation ContactsViewController

- (id)init {
    self = [super init];
    if (self) {
        self.delegate = self;
        self.peoplePickerDelegate = self;
        self.title = NSLocalizedString(@"Contacts", nil);
        self.tabBarItem.image = [UIImage imageNamed:@"contacts"];
        self.searchDisplayController.delegate = self;
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)dashboard {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Log out", nil) message:NSLocalizedString(@"Are you sure you want to log out?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No", nil) otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
    [alert show];
    alert.tag = DASHBOARD_ALERT_TAG;
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == DASHBOARD_ALERT_TAG) {
        if (buttonIndex == 1) {
            [[VoysRequestOperationManager sharedRequestOperationManager] logout];
        }
    }
}

#pragma mark - Navigation controller delegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (viewController.searchDisplayController) {
        self.oldSearchDisplayDelegate = viewController.searchDisplayController.delegate;
        viewController.searchDisplayController.delegate = self;
    }

    if ([navigationController.viewControllers indexOfObject:viewController] == 0) {
        viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]]];
        viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"logout"] style:UIBarButtonItemStyleBordered target:self action:@selector(dashboard)];

        if ([viewController isKindOfClass:[UITableViewController class]]) {
            UITableViewController *tableViewController = (UITableViewController *)viewController;
            tableViewController.tableView.sectionIndexColor = [UIColor colorWithRed:0x3c / 255.f green:0x3c / 255.f blue:0x50 / 255.f alpha:1.f];
//            tableViewController.tableView.sectionIndexColor = [UIColor colorWithRed:0x9b / 255.f green:0xc3 / 255.f blue:0x2f / 255.f alpha:1.f];
        }
    } else {
        viewController.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark - Search controller delegate

- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayControllerWillBeginSearch:)]) {
        [self.oldSearchDisplayDelegate searchDisplayControllerWillBeginSearch:controller];
    }
}

- (void) searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayControllerDidBeginSearch:)]) {
        [self.oldSearchDisplayDelegate searchDisplayControllerDidBeginSearch:controller];
    }
}

- (void) searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayControllerWillEndSearch:)]) {
        [self.oldSearchDisplayDelegate searchDisplayControllerWillEndSearch:controller];
    }
    
    if (controller.searchContentsController && controller.searchContentsController.navigationController && controller.searchContentsController.navigationController.viewControllers.count) {
        UIViewController *viewController = [controller.searchContentsController.navigationController.viewControllers objectAtIndex:0];
        if (!viewController) {
            return;
        }
        
        viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]]];
        viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"logout"] style:UIBarButtonItemStyleBordered target:self action:@selector(dashboard)];
    }
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayControllerDidEndSearch:)]) {
        [self.oldSearchDisplayDelegate searchDisplayControllerDidEndSearch:controller];
    }
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayController:didLoadSearchResultsTableView:)]) {
        [self.oldSearchDisplayDelegate searchDisplayController:controller didLoadSearchResultsTableView:tableView];
    }
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayController:willUnloadSearchResultsTableView:)]) {
        [self.oldSearchDisplayDelegate searchDisplayController:controller willUnloadSearchResultsTableView:tableView];
    }
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayController:willShowSearchResultsTableView:)]) {
        [self.oldSearchDisplayDelegate searchDisplayController:controller willShowSearchResultsTableView:tableView];
    }
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayController:didShowSearchResultsTableView:)]) {
        [self.oldSearchDisplayDelegate searchDisplayController:controller didShowSearchResultsTableView:tableView];
    }
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayController:willHideSearchResultsTableView:)]) {
        [self.oldSearchDisplayDelegate searchDisplayController:controller willHideSearchResultsTableView:tableView];
    }
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayController:didHideSearchResultsTableView:)]) {
        [self.oldSearchDisplayDelegate searchDisplayController:controller didHideSearchResultsTableView:tableView];
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayController:shouldReloadTableForSearchString:)]) {
        return [self.oldSearchDisplayDelegate searchDisplayController:controller shouldReloadTableForSearchString:searchString];
    }
    return NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    if ([self.oldSearchDisplayDelegate respondsToSelector:@selector(searchDisplayController:shouldReloadTableForSearchScope:)]) {
        return [self.oldSearchDisplayDelegate searchDisplayController:controller shouldReloadTableForSearchScope:searchOption];
    }
    return NO;
}

#pragma mark - People picker delegaate

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {

    AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
    return [appDelegate handlePerson:person property:property identifier:identifier];
}

@end
