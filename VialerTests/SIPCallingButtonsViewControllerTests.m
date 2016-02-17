//
//  SIPCallingButtonsViewControllerTests.m
//  Copyright © 2016 VoIPGRID. All rights reserved.
//

#import <OCMock/OCMock.h>
#import "SIPCallingButtonsViewController.h"
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
@end
