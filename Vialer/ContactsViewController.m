//
//  ContactsViewController.m
//  Vialer
//
//  Created by Reinier Wieringa on 06/11/13.
//  Copyright (c) 2014 VoIPGRID. All rights reserved.
//

#import "ContactsViewController.h"
#import "VoIPGRIDRequestOperationManager.h"
#import "AppDelegate.h"

#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@interface ABPeoplePickerNavigationController ()
- (void)setAllowsCancel:(BOOL)allowsCancel;
@end

@interface ContactsViewController()
@property (nonatomic, retain) id<UISearchDisplayDelegate> oldSearchDisplayDelegate;
@property (nonatomic, strong) UIColor *tableTintColor;
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

        [self setAllowsCancel:NO];

        NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"]];
        NSAssert(config != nil, @"Config.plist not found!");

        NSArray *tableTintColor = [[config objectForKey:@"Tint colors"] objectForKey:@"Table"];
        NSAssert(tableTintColor != nil && tableTintColor.count == 3, @"Tint colors - Table not found in Config.plist!");
        self.tableTintColor = [UIColor colorWithRed:[tableTintColor[0] intValue] / 255.f green:[tableTintColor[1] intValue] / 255.f blue:[tableTintColor[2] intValue] / 255.f alpha:1.f];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[[GAI sharedInstance] defaultTracker] set:kGAIScreenName value:[NSStringFromClass([self class]) stringByReplacingOccurrencesOfString:@"ViewController" withString:@""]];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createAppView]  build]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - Navigation controller delegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (viewController.searchDisplayController) {
        if (viewController.searchDisplayController.delegate != self) {
            self.oldSearchDisplayDelegate = viewController.searchDisplayController.delegate;
            viewController.searchDisplayController.delegate = self;
        }
    }

    if ([navigationController.viewControllers indexOfObject:viewController] == 0) {
        viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]]];
        viewController.navigationItem.rightBarButtonItem = nil;
        
        if ([viewController isKindOfClass:[UITableViewController class]]) {
            UITableViewController *tableViewController = (UITableViewController *)viewController;
            tableViewController.tableView.sectionIndexColor = self.tableTintColor;
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f) {
                tableViewController.tableView.tintColor = self.tableTintColor;
            }
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
        viewController.navigationItem.rightBarButtonItem = nil;
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

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    AppDelegate *appDelegate = ((AppDelegate *)[UIApplication sharedApplication].delegate);
    [appDelegate handlePerson:person property:property identifier:identifier];
}

@end
