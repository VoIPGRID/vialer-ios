//
//  ContactModel.m
//  Vialer
//
//  Created by Redmer Loen on 12-10-15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import "ContactModel.h"

@interface ContactModel()
@property (nonatomic, strong) CNContactStore *contactStore;
@property (nonatomic, strong) NSMutableDictionary *contactsSections;
@property (nonatomic, strong) NSMutableArray *contactsSearchResult;
@end

@implementation ContactModel

# pragma mark - Lazy loading properties
- (CNContactStore *)contactStore {
    if (!_contactStore) {
        _contactStore = [[CNContactStore alloc] init];
    }
    return _contactStore;
}

- (NSMutableArray *)contactsSearchResult {
    if (!_contactsSearchResult) {
        _contactsSearchResult = [NSMutableArray array];
    }
    return _contactsSearchResult;
}

- (NSMutableDictionary *)contactsSections {
    if (!_contactsSections) {
        _contactsSections = [NSMutableDictionary dictionary];
    }
    return _contactsSections;
}

- (void)getContacts:(void (^)())completion {
    id keysToFetch = @[[CNContactViewController descriptorForRequiredKeys]];
    CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
    fetchRequest.sortOrder = CNContactSortOrderGivenName;

    [self.contactsSections removeAllObjects];

    BOOL success = [self.contactStore enumerateContactsWithFetchRequest:fetchRequest error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {

        NSString *firstChar = [self getFirstChar:contact];

        if (![self.contactsSections objectForKey:firstChar]) {
            [self.contactsSections setObject:[NSMutableArray array] forKey:firstChar];
        }

        NSMutableArray *contacts = [self.contactsSections objectForKey:firstChar];
        [contacts addObject:contact];

        [self.contactsSections setObject:contacts forKey:firstChar];
    }];

    if (success && completion) {
        completion();
    }
}

- (void)searchContacts:(NSString *)searchText withCompletion:(void (^)())completion {
    [self.contactsSearchResult removeAllObjects];

    if (!searchText) {
        if (completion) {
            completion();
        }
    }

    id keysToFetch = @[[CNContactViewController descriptorForRequiredKeys]];
    CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
    fetchRequest.sortOrder = CNContactSortOrderGivenName;
    fetchRequest.predicate = [CNContact predicateForContactsMatchingName:searchText];

    BOOL success = [self.contactStore enumerateContactsWithFetchRequest:fetchRequest error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
        [self.contactsSearchResult addObject:contact];
    }];

    if (success && completion) {
        completion();
    }
}

- (NSString *)getFirstChar:(CNContact *)contact {
    NSString *firstChar = [[[CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName] substringToIndex:1] capitalizedString];
    NSRange match = [firstChar rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]
                                               options:0
                                                 range:[firstChar rangeOfComposedCharacterSequenceAtIndex:0]];
    if (match.location == NSNotFound) {
        firstChar = @"#";
    }

    return firstChar;
}

- (NSInteger)countContactSection:(NSString*)section {
    return [[self getContactsAtSection:section] count];
}

- (NSArray *)getContactsAtSection:(NSString *)section {
    return [self.contactsSections objectForKey:section];
}

- (CNContact *)getContactsAtSectionAndIndex:(NSString *)section andIndex:(NSInteger)index {
    return [[self.contactsSections objectForKey:section] objectAtIndex:index];
}

- (NSInteger)countSearchContacts {
    return [self.contactsSearchResult count];
}

- (CNContact *)getSearchContactAtIndex:(NSInteger)index {
    return [self.contactsSearchResult objectAtIndex:index];
}

- (CNContactStore *)getContactStore {
    return self.contactStore;
}

@end
