//
//  PhoneNumberModel.h
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <ContactsUI/ContactsUI.h>
#import <Foundation/Foundation.h>
#import <VialerSIPLib/VialerSIPLib.h>

@interface PhoneNumberModel : NSObject

@property (readonly, nonatomic) NSString * _Nullable displayName;
@property (readonly, nonatomic) NSString * _Nullable phoneNumberLabel;
@property (readonly, nonatomic) NSString * _Nonnull contactIdentifier;
@property (readonly, nonatomic) NSString * _Nonnull foundContactPhoneNumber;
@property (readonly, nonatomic) NSString * _Nonnull callerInfo;

/**
 *  Get caller name/data from the given CNContact and the phone number.
 *
 *  @param contact     CNContact instance.
 *  @param phoneNumber Phonenumber to match in the given contact param.
 *  @param completion  A block that will be called after the fetch attempt. It will return this model as return data.
 */
+ (void)getCallNameFromContact:(CNContact * _Nonnull)contact andPhoneNumber:(NSString * _Nonnull)phoneNumber withCompletion:(void (^ _Nullable)(PhoneNumberModel * _Nonnull phoneNumberModel))completion;

/**
 *  Get caller name/data from the given VSLCall
 *
 *  @param call       VSLCall instance.
 *  @param completion A block that will be called after the fetch attempt. It will return this model as return data.
 */
+ (void)getCallName:(VSLCall * _Nonnull)call withCompletion:(void (^ _Nullable)(PhoneNumberModel * _Nonnull phoneNumberModel))completion;
@end
