//
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

import XCTest

class SnapshotUITests: XCTestCase {

    var app:XCUIApplication!
    var interruptionHandler: NSObjectProtocol!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()

        // This handler will tap OK on the iOS generated authorization alerts (Microphone, Contacts ...)
        self.interruptionHandler = addUIInterruptionMonitor(withDescription: "Access privileges alert") {
            self.waitForElementToBeHittable($0.buttons.element(boundBy: 1), andHit: true)
            return true
        }

        continueAfterFailure = true
        setupSnapshot(app)
        app.launchArguments = ["ScreenshotRun", "NoAnimations"]
        app.launch()
    }

    override func tearDown() {
        removeUIInterruptionMonitor(self.interruptionHandler)
        app = nil
        super.tearDown()
    }

    /**
     * This is the UI Test which takes the actual screenshots. Screenshots are taken in a different order as shown on the app store (efficiency)
     * but this is corrected by prefixing with a number (01-05)
     * If the test fails without an apparent reason, try resetting the simulator. (Simulator -> Reset Content and Settings)
     */
    func testSnapshotScreenshotRun() {
        let usernameTextField = app.textFields["onboarding.loginView.username.textfield"]
        waitForElementToBeHittable(usernameTextField, andHit: true)
        waitForElementToBeHittable(usernameTextField, andHit: true)
        usernameTextField.typeText(Constants.username)

        // Snapshot of the Login screen dispalying a username.
        snapshot("01-LoginScreen")

        let passwordField = app.secureTextFields["onboarding.loginView.password.textfield"]
        waitForElementToBeHittable(passwordField , andHit: true)

        // If the test fails on this line stating: "Neither element nor
        // any descendant has keyboard focus". For the Simulator go to:
        // "Hardware" -> "Keyboard" -> Deselect "Connect Hardware Keyboard"
        passwordField.typeText(Constants.password)
        waitForElementToBeHittable(app.buttons["onboarding.loginView.login.button"] , andHit: true)

        // Now we are in the 2nd onboarding screen where the mobile number can be entered.
        let mobileNumberField = app.textFields["onboarding.configureView.mobileNumber.textfield"]
        clearUITextFieldText(mobileNumberField)

        mobileNumberField.typeText(Constants.ownNumber) // Enter mobile number.
        let continueButton = app.buttons["onboarding.configureView.continue.button"]

        // For iPhone 4(s). If the continue button does not exist, it is hidden below the keyboard.
        // Simulate a tap to make the keyboard dissapear.
        if (!continueButton.isHittable) {
            app.tap()
        }

        waitForElementToBeHittable(continueButton, andHit: true)

        // At this point, onboarding is finished, the contacts authorization has been granted and the
        // "Contacts" view is displayed.
        // Click on the Toolbar's "Contacts" button.
        let contactsTabBarButton = XCUIApplication().tabBars.buttons.element(boundBy: 1)
        waitForElementToBeHittable(contactsTabBarButton, andHit: true)
        waitForElementToBeHittable(contactsTabBarButton, andHit: true)

        // Snapshot of the "Contacts" view prefilled with Apple's default contacts.
        snapshot("05-ContactsView")

        // Click on the Toolbar's "Keypad" button.
        let dialerTabBarButton = app.tabBars.buttons.element(boundBy: 0)
        waitForElementToBeHittable(dialerTabBarButton, andHit: true)
        // Click on the navigation bar's "Hamburg menu".
        let hamburger = app.navigationBars.buttons.element(boundBy: 0)
        waitForElementToBeHittable(hamburger, andHit: true)

        sleep(2)
        // Snapshot with the sidemenu extended and part of the dialer shown.
        snapshot("04-SideMenuWithDailer")

        waitForElementToBeHittable(dialerTabBarButton, andHit: true)

        for number in Constants.numberToDail.characters {
            waitForElementToBeHittable(app.buttons["DialerStoryboard.dialer.button\(number)"], andHit: true)
        }

        // Snapshot of the dialer view with a phone number entered.
        snapshot("02-DialerViewWithNumber")

        waitForElementToBeHittable(app.buttons["DialerStoryboard.CallButton"], andHit: true)
        // Snapshot of the sip call screen which is setting up the call.
        snapshot("03-SIPCallView")

        //waitForElementToBeHittable(app.buttons["declineButton"], andHit: true)
        waitForElementToBeHittable(app.buttons["SIPCallingStoryboard.HangupButton"], andHit: true)
    }

    // http://stackoverflow.com/questions/32821880/ui-test-deleting-text-in-text-field
    // Clears the given textfield of it's input.
    private func clearUITextFieldText(_ element: XCUIElement) {
        waitForElementToBeHittable(element, andHit: true)
        guard let stringValue = element.value as? String else {
            XCTFail("Tried to clear into a non string value")
            return
        }

        let deleteString: String = stringValue.characters.map { _ in "\u{8}" }.joined(separator: "")
        if deleteString.characters.count == 0 {
            XCTFail("No deleting!!")
        }

        element.typeText(deleteString)

        guard let newStringValue = element.value as? String else {
            return
        }

        if (newStringValue.characters.count > 0) {
            print("Textfield empty. count:\(stringValue.characters.count)")
            sleep(2)
            self.clearUITextFieldText(element);
        }
    }

    /**
     * Function waits for the given XCUIElement to become hittable or times out after 60 sec.
     * modified example from: http://masilotti.com/xctest-helpers/
     */
    private func waitForElementToBeHittable(_ element: XCUIElement, file: String = #file, line: UInt = #line, andHit: Bool)  {
        let existsPredicate = NSPredicate(format: "hittable == true")
        expectation(for: existsPredicate, evaluatedWith: element, handler: nil)

        waitForExpectations(timeout: 10) { (error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after 10 seconds."
                self.recordFailure(withDescription: message,
                    inFile: file, atLine: line, expected: true)
            }
        }
        if (andHit) {
            element.tap()
        }
    }
}
