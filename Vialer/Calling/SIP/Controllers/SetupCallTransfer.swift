import Foundation
import PhoneLib

class SetupCallTransfer: UIViewController {

    enum SegueIdentifier: String {
        case unwindToFirstCall = "UnwindToFirstCallSegue"
        case secondCallActive = "SecondCallActiveSegue"
    }
    
    var callObserversSet = false // Keep track if observers are set to prevent removing unset observers.
    
    var firstCall: Call? {
        didSet {
            updateUI()
        }
    }
    var firstCallPhoneNumberLabelText: String? {
        didSet {
            updateUI()
        }
    }

    var currentCall: Call?

    func updateUI() {
        // Implement in sub class.
    }
}
