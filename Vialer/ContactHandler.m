//
//  ContactHandler.m
//  Vialer
//
//  Created by Steve Overmars on 20-03-15.
//  Copyright (c) 2015 VoIPGRID. All rights reserved.
//

#import "ContactHandler.h"

@interface ContactHandler ()

@property (nonatomic, assign) id presentingViewControllerDelegate;
@property (nonatomic, assign) id<ABNewPersonViewControllerDelegate> theNewPersonViewControllerDelegate;
@property (nonatomic, copy) NewPersonCompletionBlock newPersonCompletionBlock;

@end

@implementation ContactHandler

+ (ContactHandler *)sharedContactHandler {
    static dispatch_once_t pred;
    static ContactHandler *_sharedContactHandler = nil;
    
    dispatch_once(&pred, ^{
        _sharedContactHandler = [[self alloc] init];
    });
    return _sharedContactHandler;
}

- (void)presentNewPersonViewControllerWithPerson:(ABRecordRef)newPerson
                presentingViewControllerDelegate:(UIViewController *)presentingViewControllerDelegate
                                      completion:(NewPersonCompletionBlock)completion {
    
    self.presentingViewControllerDelegate = presentingViewControllerDelegate;
    NSAssert(self.presentingViewControllerDelegate != nil, @"Contacthandler's presentingViewControllerDelegate property cannot be nil." );
    
    self.theNewPersonViewControllerDelegate = self;
    
    self.newPersonCompletionBlock = completion;
    
    [self setupAndPresentNewPersonViewControllerWithPerson:newPerson
                          presentingViewControllerDelegate:(UIViewController <ABNewPersonViewControllerDelegate> *)self.presentingViewControllerDelegate
                           newPersonViewControllerDelegate:self.theNewPersonViewControllerDelegate];
    
}

- (void)presentNewPersonViewControllerWithPerson:(ABRecordRef)newPerson
                presentingViewControllerDelegate:(UIViewController <ABNewPersonViewControllerDelegate>*)presentingViewControllerDelegate {
    
    self.presentingViewControllerDelegate = presentingViewControllerDelegate;
    NSAssert(self.presentingViewControllerDelegate != nil, @"Contacthandler's presentingViewControllerDelegate property cannot be nil." );
    
    self.theNewPersonViewControllerDelegate = presentingViewControllerDelegate;
    
    [self setupAndPresentNewPersonViewControllerWithPerson:newPerson
                          presentingViewControllerDelegate:self.presentingViewControllerDelegate
                           newPersonViewControllerDelegate:self.theNewPersonViewControllerDelegate];
}

- (void)setupAndPresentNewPersonViewControllerWithPerson:(ABRecordRef)newPerson
                        presentingViewControllerDelegate:(UIViewController <ABNewPersonViewControllerDelegate>*)presentingViewControllerDelegate
                         newPersonViewControllerDelegate:(id<ABNewPersonViewControllerDelegate>)theNewPersonViewControllerDelegate {
    
    // Create and set-up the new person view controller
    ABNewPersonViewController* newPersonViewController = [[ABNewPersonViewController alloc] init];
    [newPersonViewController setDisplayedPerson:newPerson];
    [newPersonViewController setNewPersonViewDelegate:theNewPersonViewControllerDelegate];
    
    // Wrap in a nav controller and display
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newPersonViewController];
    [presentingViewControllerDelegate presentViewController:navController animated:YES completion:nil];
}

#pragma mark - ABNewPersonViewControllerDelegate

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)person {
    [newPersonView dismissViewControllerAnimated:YES completion:^{
        if (self.newPersonCompletionBlock) {
            self.newPersonCompletionBlock(newPersonView, person);
        }
        self.presentingViewControllerDelegate = nil;
        self.theNewPersonViewControllerDelegate = nil;
    }];
}

@end
