//
//  ContactModel.m
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
@property (nonatomic, strong) dispatch_queue_t concurrentContactQueue;
@end

@implementation ContactModel

#pragma mark - initialization

+ (instancetype)defaultContactModel {
    static ContactModel *_defaultContactModel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultContactModel = [[ContactModel alloc] init];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [_defaultContactModel refreshAllContacts];
        });
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
        _fetchRequest.sortOrder = CNContactSortOrderUserDefault;
    }
    return _fetchRequest;
}

- (NSArray *)sectionTitles {
    __block NSArray *titles;
    dispatch_sync(self.concurrentContactQueue, ^{
        if ([self.contactsSections count]) {
            NSMutableArray *sortedSectionTitles =[[[self.contactsSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
            // If there is a pound character, move it to last position
            if ([sortedSectionTitles[0] isEqualToString:@"#"]) {
                [sortedSectionTitles addObject:sortedSectionTitles[0]];
                [sortedSectionTitles removeObjectAtIndex:0];
            }
            titles = [sortedSectionTitles copy];
        }
    });
    return titles;
}

- (NSArray *)searchResults {
    __block NSArray *results;
    dispatch_sync(self.concurrentContactQueue, ^{
        results = [self.contactsSearchResult copy];
    });
    return results;
}

# pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.concurrentContactQueue = dispatch_queue_create("com.voipgrid.vialer.Contacts", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

# pragma mark - actions

- (BOOL)refreshAllContacts {
    __block BOOL success;
    dispatch_barrier_sync(self.concurrentContactQueue, ^{
        NSMutableDictionary *newContacts = [NSMutableDictionary dictionary];
        NSMutableArray *newAllContacts = [NSMutableArray array];

        NSError *error;
        success = [self.contactStore enumerateContactsWithFetchRequest:self.fetchRequest error:&error usingBlock:^(CNContact *contact, BOOL *stop) {
            [newAllContacts addObject:contact];
            NSString *firstChar = [self getFirstChar:contact];

            if (!newContacts[firstChar]) {
                newContacts[firstChar] = [NSMutableArray array];
            }
            [newContacts[firstChar] addObject:contact];
        }];

        if (error) {
            DDLogError(@"Contact errors: %@", error);
        }

        if (success) {
            self.allContacts = newAllContacts;
            self.contactsSections = newContacts;
        }
    });
    return success;
}

- (BOOL)searchContacts:(NSString *)searchText {
    __block BOOL success;
    dispatch_barrier_sync(self.concurrentContactQueue, ^{
        [self.contactsSearchResult removeAllObjects];

        if (!searchText) {
            success = NO;
        } else {
            CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:self.keysToFetch];
            fetchRequest.sortOrder = CNContactSortOrderUserDefault;
            fetchRequest.predicate = [CNContact predicateForContactsMatchingName:searchText];

            success = [self.contactStore enumerateContactsWithFetchRequest:fetchRequest error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
                [self.contactsSearchResult addObject:contact];
            }];
        }
    });
    return success;
}

- (NSString *)getFirstChar:(CNContact *)contact {
    NSString *familyName = [contact familyName];
    NSString *givenName = [contact givenName];
    NSString *firstChar;

    if ([CNContactFormatter nameOrderForContact:contact] == CNContactDisplayNameOrderFamilyNameFirst && familyName.length > 0) {
        firstChar = [[familyName substringToIndex:1] capitalizedString];
    } else if (givenName.length > 0) {
        firstChar = [[givenName substringToIndex:1] capitalizedString];
    }

    NSRange match = [firstChar rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]
                                               options:0
                                                 range:[firstChar rangeOfComposedCharacterSequenceAtIndex:0]];
    if (!firstChar || match.location == NSNotFound) {
        firstChar = @"#";
    }

    return firstChar;
}

- (CNContact *)getSelectedContactOnIdentifier:(NSString *)contactIdentifier {
    __block CNContact *contact;
    dispatch_sync(self.concurrentContactQueue, ^{
        contact = [self.contactStore unifiedContactWithIdentifier:contactIdentifier keysToFetch:self.keysToFetch error:nil];
    });
    return contact;
}

- (NSArray *)getContactsAtSection:(NSInteger)sectionIndex {
    __block NSArray *contactsAtSection;
    dispatch_sync(self.concurrentContactQueue, ^{
        contactsAtSection = self.contactsSections[self.sectionTitles[sectionIndex]];
    });
    return contactsAtSection;
}

- (CNContact *)getContactsAtSection:(NSInteger)section andIndex:(NSInteger)index {
    __block CNContact *contact;
    dispatch_sync(self.concurrentContactQueue, ^{
        contact = [[self.contactsSections objectForKey:self.sectionTitles[section]] objectAtIndex:index];
    });
    return contact;
}

- (NSInteger)countSearchContacts {
    __block NSInteger count;
    dispatch_sync(self.concurrentContactQueue, ^{
        count = [self.contactsSearchResult count];
    });
    return count;
}

- (CNContact *)getSearchContactAtIndex:(NSInteger)index {
    __block CNContact *contact;
    dispatch_sync(self.concurrentContactQueue, ^{
        contact = [self.contactsSearchResult objectAtIndex:index];
    });
    return contact;
}

- (CNContactStore *)getContactStore {
    __block CNContactStore *store;
    dispatch_sync(self.concurrentContactQueue, ^{
        store = self.contactStore;
    });
    return store;
}

@end
