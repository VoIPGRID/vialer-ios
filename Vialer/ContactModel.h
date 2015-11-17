//
//  ContactsModel.h
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContactsUI/ContactsUI.h"

@interface ContactModel : NSObject


+ (instancetype)defaultContactModel;

/**
 Array with the section Titles. Sorted alphabetically.
 */
@property (nonatomic, readonly) NSArray *sectionTitles;

/**
 Array with the search results.
 */
@property (nonatomic, readonly) NSArray *searchResults;

@property (nonatomic, readonly) NSArray *allContacts;

/**
 Get all contacts that are available on your phone.
 */
- (BOOL)refreshAllContacts;

/**
 Search in the contacts based on  the given searchText.

 @param searchText The string which is used to search for a contact.

 @return BOOL succesfull filtering of contacts
 */
- (BOOL)searchContacts:(NSString *)searchText;

/**
 Get all the contacts at a specific sections.

 @param sectionIndex the index that is used to get the contacts out of the contacts dict.

 @return NSArray the contacts at the given section.
 */
- (NSArray *)getContactsAtSection:(NSInteger)sectionIndex;

/**
 Get the contact that is located in a speciific section and index.

 @param section the character of the section.
 @param index the index of where to loop in the section.

 @return CNContact at the given in the section and index.
 */
- (CNContact *)getContactsAtSection:(NSInteger)section andIndex:(NSInteger)index;

/**
 Get the CNContactStore that is used in the model.

 @return CNContactStore the used contact store.
 */
- (CNContactStore *)getContactStore;

/**
 Get a contact based on its CNContact identifier.

 @param contactIdentifier The identifier that is linked to a CNContact.

 @return CNContact
 */
- (CNContact *)getSelectedContactOnIdentifier:(NSString *)contactIdentifier;

@end
