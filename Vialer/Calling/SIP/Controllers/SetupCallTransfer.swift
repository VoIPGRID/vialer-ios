import Foundation

class SetupCallTransfer: UIViewController {

    enum SegueIdentifier: String {
        case unwindToFirstCall = "UnwindToFirstCallSegue"
        case secondCallActive = "SecondCallActiveSegue"
    }
    
    var firstCall: VSLCall? {
        didSet {
            updateUI()
        }
    }
    var firstCallPhoneNumberLabelText: String? {
        didSet {
            updateUI()
        }
    }

    var currentCall: VSLCall?
    var callManager = VialerSIPLib.sharedInstance().callManager

    func updateUI() {
        // Implement in sub class.
    }
}
