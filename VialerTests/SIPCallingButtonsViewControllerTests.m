//
//  SIPCallingButtonsViewControllerTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <OCMock/OCMock.h>
#import "NumberPadViewController.h"
#import "SIPCallingButtonsViewController.h"
#import "SIPCallingViewController.h"
#import <VialerSIPLib-iOS/VialerSIPLib.h>
#import <XCTest/XCTest.h>

@interface SIPCallingButtonsViewControllerTests : XCTestCase
@property (strong, nonatomic) SipCallingButtonsViewController *sipCallingButtonsVC;
@end

@implementation SIPCallingButtonsViewControllerTests

- (void)setUp {
    [super setUp];
    self.sipCallingButtonsVC = (SipCallingButtonsViewController *)[[UIStoryboard storyboardWithName:@"SIPCallingStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"SipCallingButtonsViewController"];
    [self.sipCallingButtonsVC loadViewIfNeeded];
}

- (void)testViewControllerHasAHoldButton {
    XCTAssertNotNil(self.sipCallingButtonsVC.holdButton, @"There should be a hold button");
}

- (void)testViewControllerPushHoldWillAskCallToHold {
    id callMock = OCMClassMock([VSLCall class]);
    self.sipCallingButtonsVC.call = callMock;

    [self.sipCallingButtonsVC holdButtonPressed:nil];

    OCMVerify([callMock toggleHold:[OCMArg anyObjectRef]]);
}

- (void)testViewControllerHasAMuteButton {
    XCTAssertNotNil(self.sipCallingButtonsVC.muteButton, @"There should be a mute button");
}

- (void)testViewControllerPusMuteWillAskCallToHold {
    id callMock = OCMClassMock([VSLCall class]);
    self.sipCallingButtonsVC.call = callMock;

    [self.sipCallingButtonsVC muteButtonPressed:nil];

    OCMVerify([callMock toggleMute:[OCMArg anyObjectRef]]);
}

- (void)testViewControllerHasASpeakerButton {
    XCTAssertNotNil(self.sipCallingButtonsVC.speakerButton, @"There should be a speaker button");
}

- (void)testViewControllerPusMuteWillAskCallToSpeakerTheCall {
    id callMock = OCMClassMock([VSLCall class]);
    self.sipCallingButtonsVC.call = callMock;

    [self.sipCallingButtonsVC speakerButtonPressed:nil];

    OCMVerify([callMock toggleSpeaker]);
}

- (void)testViewControllerHasAKeypadButton {
    XCTAssertNotNil(self.sipCallingButtonsVC.keypadButton, @"There should be a keypad button");
}

- (void)testViewControllerConformsToProtocol {
    XCTAssertTrue([self.sipCallingButtonsVC conformsToProtocol:@protocol(NumberPadViewControllerDelegate)], @"The viewcontroller should confirm to the protocol.");
}

- (void)testViewControllerWillSendDMFToCall {
    id callMock = OCMClassMock([VSLCall class]);
    self.sipCallingButtonsVC.call = callMock;

    [self.sipCallingButtonsVC numberPadPressedWithCharacter:@"1"];

    OCMVerify([callMock sendDTMF:[OCMArg isEqual:@"1"] error:[OCMArg anyObjectRef]]);
}

- (void)testViewControllerWillSendDMFToDelegate {
    id callMock = OCMClassMock([VSLCall class]);
    self.sipCallingButtonsVC.call = callMock;
    id delegateMock = OCMClassMock([SIPCallingViewController class]);
    self.sipCallingButtonsVC.delegate = delegateMock;

    [self.sipCallingButtonsVC numberPadPressedWithCharacter:@"1"];

    OCMVerify([delegateMock DTMFSend:[OCMArg isEqual:@"1"]]);
}

- (void)testHideNumberpadWillTellDelegate {
    id delegateMock = OCMClassMock([SIPCallingViewController class]);
    self.sipCallingButtonsVC.delegate = delegateMock;

    [self.sipCallingButtonsVC hideNumberpad];

    OCMVerify([delegateMock keypadChangedVisibility:NO]);
}

@end
