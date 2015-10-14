//
//  ContactHandler.h
//  Vialer
//
//  Created by Steve Overmars on 20-03-15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import <AddressBookUI/AddressBookUI.h>
#import <Foundation/Foundation.h>

@interface ContactHandler : NSObject <ABNewPersonViewControllerDelegate>

typedef void(^NewPersonCompletionBlock)(ABNewPersonViewController *newPersonView, ABRecordRef person);

+ (ContactHandler *)sharedContactHandler;

/**
 Use this method when you want to present a ABNewPersonViewController and let ContactHandler act as the ABNewPersonViewControllerDelegate and have the resulting data be in the completion block.
 
 @param newPerson ABRecordRef (possibly created with ABPersonCreate()) of a new person with prefilled information. Pass NULL if you don't want to use any prefilled information.
 @param presentingViewControllerDelegate The view controller that will present the ABNewPersonViewController.
 @param completion Completion block that is executed when the ABNewPersonViewController is dismissed.
 */
- (void)presentNewPersonViewControllerWithPerson:(ABRecordRef)newPerson
                presentingViewControllerDelegate:(UIViewController *)presentingViewControllerDelegate
                                      completion:(NewPersonCompletionBlock)completion;

/**
 Use this method when you want to present a ABNewPersonViewController and also let the presentingViewControllerDelegate act as the ABNewPersonViewControllerDelegate..
 
 @param newPerson ABRecordRef (possibly created with ABPersonCreate()) of a new person with prefilled information. Pass NULL if you don't want to use any prefilled information.
 @param presentingViewControllerDelegate The view controller that will present the ABNewPersonViewController and also conform to the ABNewPersonViewControllerDelegate protocol.
 */
- (void)presentNewPersonViewControllerWithPerson:(ABRecordRef)newPerson
                presentingViewControllerDelegate:(UIViewController <ABNewPersonViewControllerDelegate>*)presentingViewControllerDelegate;

@end
