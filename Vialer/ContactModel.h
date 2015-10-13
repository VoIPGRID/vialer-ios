//
//  ContactsModel.h
//  Vialer
//
//  Created by Redmer Loen on 12-10-15.
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContactsUI/ContactsUI.h"

@interface ContactModel : NSObject

/**
 Get all contacts that are available on your phone. Uses a completion block when it is done.
 */
- (void)getContacts:(void (^)())completion;

/**
 Search in the contacts based on  the given searchText.

 @param searchText The string which is used to search for a contact.

 @return Uses a completion block which returns an NSArray with CNContacts in it.
 */
- (void)searchContacts:(NSString *)searchText withCompletion:(void (^)())completion;

/**
 Count how many contacts there are in a section. A section is the beginning character of a contact.

 @param section the character to count how many contacts are in a section.

 @returns NSInteger the number of found contacts at the section.
 */
- (NSInteger)countContactSection:(NSString*)section;

/**
 Get all the contacts at a specific sections.

 @param section the character that is used to get the contacts out of the contacts dict.

 @return NSArray the contacts at the given section.
 */
- (NSArray *)getContactsAtSection:(NSString*)section;

/**
 Get the contact that is located in a speciific section and index.

 @param section the character of the section.
 @param index the index of where to loop in the section.

 @return CNContact at the given in the section and index.
 */
- (CNContact *)getContactsAtSectionAndIndex:(NSString*)section andIndex:(NSInteger)index;

/**
 Get the number of results of the search.

 @return NSInteger the number of found contacts.
 */
- (NSInteger)countSearchContacts;

/**
 Get a contact that is located at an index of the search results.

 @param index The index that is used to get the contact out of the search results.

 @return CNContact located at the index.
 */
- (CNContact *)getSearchContactAtIndex:(NSInteger)index;

/**
 Get the CNContactStore that is used in the model.

 @return CNContactStore the used contact store.
 */
- (CNContactStore *)getContactStore;

@end
