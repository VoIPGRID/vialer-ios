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
@property (nonatomic, strong) NSArray *allContacts;
@property (nonatomic, strong) NSArray *keysToFetch;
@property (nonatomic, strong) CNContactFetchRequest *fetchRequest;

@property (nonatomic, strong) NSArray *sectionTitles;

@end

@implementation ContactModel

#pragma mark - initialization

+ (instancetype)defaultContactModel {
    static ContactModel *_defaultContactModel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        _defaultContactModel = [[ContactModel alloc] init];
        [_defaultContactModel refreshAllContacts];
    });
    return _defaultContactModel;
}

# pragma mark - properties

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

- (NSArray *)keysToFetch {
    if (!_keysToFetch) {
        _keysToFetch = @[[CNContactViewController descriptorForRequiredKeys], CNContactPhoneNumbersKey];
    }
    return _keysToFetch;
}

- (CNContactFetchRequest *)fetchRequest {
    if (!_fetchRequest) {
        _fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:self.keysToFetch];
        _fetchRequest.sortOrder = CNContactSortOrderGivenName;
    }
    return _fetchRequest;
}

- (NSArray *)sectionTitles {
    if (![self.contactsSections count]) {
        return nil;
    }
    NSMutableArray *sortedSectionTitles =[[[self.contactsSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
    // If there is a pound character, move it to last position
    if ([sortedSectionTitles[0] isEqualToString:@"#"]) {
        [sortedSectionTitles addObject:sortedSectionTitles[0]];
        [sortedSectionTitles removeObjectAtIndex:0];
    }
    return [sortedSectionTitles copy];
}

- (NSArray *)searchResults {
    return [self.contactsSearchResult copy];
}

# pragma mark - actions

- (BOOL)refreshAllContacts {
    NSMutableDictionary *newContacts = [NSMutableDictionary dictionary];
    NSMutableArray *newAllContacts = [NSMutableArray array];

    BOOL success = [self.contactStore enumerateContactsWithFetchRequest:self.fetchRequest error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
        [newAllContacts addObject:contact];
        NSString *firstChar = [self getFirstChar:contact];

        if (!newContacts[firstChar]) {
            newContacts[firstChar] = [NSMutableArray array];
        }
        [newContacts[firstChar] addObject:contact];
    }];

    if (success) {
        self.allContacts = newAllContacts;
        self.contactsSections = newContacts;
    }
    return success;
}

- (BOOL)searchContacts:(NSString *)searchText {
    [self.contactsSearchResult removeAllObjects];

    if (!searchText) {
        return NO;
    }

    CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:self.keysToFetch];
    fetchRequest.sortOrder = CNContactSortOrderGivenName;
    fetchRequest.predicate = [CNContact predicateForContactsMatchingName:searchText];

    BOOL success = [self.contactStore enumerateContactsWithFetchRequest:fetchRequest error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
        [self.contactsSearchResult addObject:contact];
    }];

    return success;
}

- (NSString *)getFirstChar:(CNContact *)contact {
    NSString *firstChar = [[[CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName] substringToIndex:1] capitalizedString];
    NSRange match = [firstChar rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]
                                               options:0
                                                 range:[firstChar rangeOfComposedCharacterSequenceAtIndex:0]];
    if (!firstChar || match.location == NSNotFound) {
        firstChar = @"#";
    }

    return firstChar;
}

- (CNContact *)getSelectedContactOnIdentifier:(NSString *)contactIdentifier {

    return [self.contactStore unifiedContactWithIdentifier:contactIdentifier keysToFetch:self.keysToFetch error:nil];
}

- (NSArray *)getContactsAtSection:(NSInteger)sectionIndex {
    return self.contactsSections[self.sectionTitles[sectionIndex]];
}

- (CNContact *)getContactsAtSection:(NSInteger)section andIndex:(NSInteger)index {
    return [[self.contactsSections objectForKey:self.sectionTitles[section]] objectAtIndex:index];
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
