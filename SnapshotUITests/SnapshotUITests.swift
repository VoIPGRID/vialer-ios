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
        self.interruptionHandler = addUIInterruptionMonitorWithDescription("Access privileges alert") {
            $0.buttons.elementBoundByIndex(1).tap()
            //$0.buttons["OK"].tap() // As an alternative option, need to evaluate which works better
            return true
        }

        continueAfterFailure = true
        setupSnapshot(app)
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
        waitForElementToBeHittable(usernameTextField)
        usernameTextField.tap()
        usernameTextField.typeText(Constants.username)

        // Snapshot of the Login screen dispalying a username.
        snapshot("01-LoginScreen")

        let passwordField = app.secureTextFields["onboarding.loginView.password.textfield"]
        waitForElementToBeHittable(passwordField)
        passwordField.tap()
        passwordField.typeText(Constants.password)
        app.buttons["onboarding.loginView.login.button"].tap()

        // Now we are in the 2nd onboarding screen where the mobile number can be entered.
        let mobileNumberField = app.textFields["onboarding.configureView.mobileNumber.textfield"]
        waitForElementToBeHittable(mobileNumberField)

        clearUITextFieldText(mobileNumberField)

        mobileNumberField.typeText(Constants.ownNumber) // Enter mobile number.
        let continueButton = app.buttons["onboarding.configureView.continue.button"]

        // For iPhone 4(s). If the continue button does not exist, it is hidden below the keyboard.
        // Simulate a tap to make the keyboard dissapear.
        if (!continueButton.hittable) {
            app.tap()
        }

        continueButton.tap()

        // At this point, onboarding is finished, the contacts authorization has been granted and the
        // "Contacts" view is displayed.
        // Click on the Toolbar's "Contacts" button.
        let contactsTabBarButton = XCUIApplication().tabBars.buttons.elementBoundByIndex(1)
        waitForElementToBeHittable(contactsTabBarButton)
        contactsTabBarButton.tap()

        // Snapshot of the "Contacts" view prefilled with Apple's default contacts.
        snapshot("05-ContactsView")

        // Click on the Toolbar's "Keypad" button.
        let dialerTabBarButton = app.tabBars.buttons.elementBoundByIndex(0)
        dialerTabBarButton.tap()
        // Click on the navigation bar's "Hamburg menu".
        app.navigationBars.buttons.elementBoundByIndex(0).tap()

        // Snapshot with the sidemenu extended and part of the dialer shown.
        snapshot("04-SideMenuWithDailer")

        dialerTabBarButton.tap()

        for number in Constants.numberToDail.characters {
            app.buttons["DialerStoryboard.dialer.button\(number)"].tap()
        }

        // Snapshot of the dialer view with a phone number entered.
        snapshot("02-DialerViewWithNumber")

        app.buttons["CallingStoryboard.CallButton"].tap()
        // Snapshot of the sip call screen which is setting up the call.
        snapshot("03-SIPCallView")
    }

    // http://stackoverflow.com/questions/32821880/ui-test-deleting-text-in-text-field
    // Clears the given textfield of it's input.
    private func clearUITextFieldText(element: XCUIElement) {
        element.tap()
        guard let stringValue = element.value as? String else {
            XCTFail("Tried to clear into a non string value")
            return
        }

        let deleteString: String = stringValue.characters.map { _ in "\u{8}" }.joinWithSeparator("")
        if deleteString.characters.count == 0 {
            XCTFail("No deleting")
        }
        element.typeText(deleteString)
    }

    /**
     * Function waits for the given XCUIElement to become hittable or times out after 60 sec.
     * modified example from: http://masilotti.com/xctest-helpers/
     */
    private func waitForElementToBeHittable(element: XCUIElement, file: String = #file, line: UInt = #line) {
        let existsPredicate = NSPredicate(format: "hittable == true")
        expectationForPredicate(existsPredicate,
            evaluatedWithObject: element, handler: nil)

        waitForExpectationsWithTimeout(60) { (error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after 60 seconds."
                self.recordFailureWithDescription(message,
                    inFile: file, atLine: line, expected: true)
            }
        }
    }
}
