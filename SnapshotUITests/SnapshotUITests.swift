//
//  Copyright © 2015 VoIPGRID. All rights reserved.
//

import XCTest

class SnapshotUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    /**
     * This is the UI Test which takes the actual screenshots. Screenshots are taken in a different order as shown on the app store (efficiency)
     * but this is corrected by prefixing with a number (01-05)
     * If the test fails without an apparent reason, try resetting the simulator. (Simulator -> Reset Content and Settings)
     */
    func testSnapshotScreenshotRun() {
        // This handler will tap OK on the iOS generated autorization alerts (Microphone, Contacts ...)
        addUIInterruptionMonitorWithDescription("Access contacts alert") {
            $0.buttons["OK"].tap()
            return true
        }

        let app = XCUIApplication()
        let usernameTextField = app.textFields["onboarding.loginView.username.textfield"]
        waitForElementToBeHittable(usernameTextField)
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

        mobileNumberField.typeText("+31612345678") //enter mobile number
        let continueButton = app.buttons["onboarding.configureView.continue.button"]

        // For iPhone 4(s). If the continue button does not exist, it is hidden below the keyboard.
        // Simulate a tap to make the keyboard dissapear.
        if (!continueButton.hittable) {
            app.tap()
        }
        continueButton.tap()

        // At this point, onboarding is finished, the contacts autorization is has been granted and the
        // "Contacts" view is displayed.
        let contactsTabBarButton = XCUIApplication().tabBars.buttons[localizeString("Contacts")]
        waitForElementToBeHittable(contactsTabBarButton)
        contactsTabBarButton.tap()

        // Snapshot of the "Contacts" view prefilled with Apple's default contacts.
        snapshot("05-ContactsView")

        let dialerTabBarButton = app.tabBars.buttons[localizeString("Keypad")]
        dialerTabBarButton.tap()
        app.navigationBars[localizeString("Keypad")].buttons["menu"].tap()

        // Snapshot with the sidemenu extended and part of the dialer shown.
        snapshot("04-SideMenuWithDailer")

        dialerTabBarButton.tap()

        for number in Constants.numberToDail.characters {
            app.buttons["CallingStoryboard.dialer.button\(number)"].tap()
        }

        // Snapshot of the dialer view with a phone number entered.
        snapshot("02-DialerViewWithNumber")

        app.buttons["CallingStoryboard.CallButton"].tap()
        // Snapshot of the two step call screen which is setting up the call.
        snapshot("03-TwoStepCallView")

        // Cancel the TwoStepCall.
        app.buttons["TwoCallingStoryboard.CancelCall.button"].tap()

        waitForElementToBeHittable(contactsTabBarButton)
    }

    // http://stackoverflow.com/questions/32821880/ui-test-deleting-text-in-text-field
    // Clears the given textfield of it's input.
    private func clearUITextFieldText(element: XCUIElement) {
        guard let stringValue = element.value as? String else {
            XCTFail("Tried to clear into a non string value")
            return
        }
        element.tap()

        var deleteString: String = ""
        for _ in stringValue.characters {
            deleteString += "\u{8}"
        }
        element.typeText(deleteString)
    }

    // https://github.com/fastlane/snapshot/issues/321
    // Function for localizing a string. Make sure the localizeble.strings file is added to
    // the "Copy bundle resources" build phase of the relevant target.
    func localizeString(key:String) -> String {
        let localizationBundle = NSBundle(path: NSBundle(forClass: SnapshotUITests.self).pathForResource(deviceLanguage, ofType: "lproj")!)
        return NSLocalizedString(key, bundle:localizationBundle!, comment: "")
    }

    /**
     * Function waits for 30 second for the given XCUIElement to become hittable.
     * modified example from: http://masilotti.com/xctest-helpers/
     */
    private func waitForElementToBeHittable(element: XCUIElement, file: String = __FILE__, line: UInt = __LINE__) {
        let existsPredicate = NSPredicate(format: "hittable == true")
        expectationForPredicate(existsPredicate,
            evaluatedWithObject: element, handler: nil)

        waitForExpectationsWithTimeout(30) { (error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after 30 seconds."
                self.recordFailureWithDescription(message,
                    inFile: file, atLine: line, expected: true)
            }
        }
    }
}
