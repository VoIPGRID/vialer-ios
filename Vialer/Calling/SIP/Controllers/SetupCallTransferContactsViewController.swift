import Foundation
import Contacts
import ContactsUI
import PhoneLib

private var myContext = 0

class SetupCallTransferContactsViewController: SetupCallTransfer, UITableViewDataSource, UITableViewDelegate, SegueHandler {
    fileprivate var contactModel = ContactModel.defaultModel
    fileprivate var callActionSheet: UIAlertController?

    @IBOutlet weak var firstCallNumberLabel: UILabel!
    @IBOutlet weak var firstCallStatusLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    override func updateUI() {
        if (firstCallPhoneNumberLabelText != nil) {
            firstCallNumberLabel?.text = firstCallPhoneNumberLabelText
        }

        guard let call = firstCall else { return }
         
        if call.simpleState == .finished {
            firstCallStatusLabel?.text = NSLocalizedString("Disconnected", comment: "Disconnected phone state")
        } else {
            firstCallStatusLabel?.text = NSLocalizedString("On hold", comment: "On hold")
        }
    }

    @IBAction func cancelPressed(_ sender: AnyObject) {
        guard let call = currentCall else {
            DispatchQueue.main.async {
                self.performSegue(segueIdentifier: .unwindToFirstCall)
            }
            return
        }
        
        let success = sip.endCall(for: call.session)
        if success == true {
            DispatchQueue.main.async {
                self.performSegue(segueIdentifier: .unwindToFirstCall)
            }
        } else {
            VialerLogError("Could not hang up current call after cancelling.")
        }
    }

}

// MARK: - Lifecycle
extension SetupCallTransferContactsViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        firstCall?.addObserver(self, forKeyPath: "callState", options: .new, context: &myContext)
//        firstCall?.addObserver(self, forKeyPath: "mediaState", options: .new, context: &myContext)
        callObserversSet = true
        
        VialerGAITracker.trackScreenForController(name: controllerName)

        updateUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if callObserversSet {
//            firstCall?.removeObserver(self, forKeyPath: "callState")
//            firstCall?.removeObserver(self, forKeyPath: "mediaState")
            callObserversSet = false
        }
    }
}

// MARK: - Table view data source
extension SetupCallTransferContactsViewController {
    func numberOfSections(in tableView: UITableView) -> Int {
        return contactModel.sectionTitles?.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return contactModel.sectionTitles?[section]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactModel.contactsAt(section: section).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let contact = contactModel.contactAt(section: indexPath.section, index: indexPath.row)

        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactsTableViewCell", for: indexPath)
        cell.textLabel?.attributedText = contactModel.attributedString(for: contact)
        return cell
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return contactModel.sectionTitles;
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32.0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = contactModel.contactAt(section: indexPath.section, index: indexPath.row)
        
        if (contact.phoneNumbers.count == 0) {
            tableView.deselectRow(at: indexPath, animated: true)
            return // No action needed since there is no number to call.
        } else if (contact.phoneNumbers.count == 1) {
            // There is just one phone number for the selected contact, so make the call.
            beginTransferByCalling(phoneNumber: contact.phoneNumbers[0].value)
        } else {
            // Create an action controller to show every number to call for the selected contact.
            let name = contactModel.displayName(for: contact)
            let callActionSheet = UIAlertController(title: name,
                                                    message: nil,
                                                    preferredStyle: .actionSheet)
            
            // Add each number of the contact as an alert action to the alert controller.
            for phoneNumber in contact.phoneNumbers {
                let label = CNLabeledValue<NSString>.localizedString(forLabel: phoneNumber.label! )
                let number = phoneNumber.value.stringValue
                let callAction = UIAlertAction(title: "\(label): \(number)", style: .default) { (action) in
                    // Make the call if the user clicks on a specific call action.
                    self.beginTransferByCalling(phoneNumber: phoneNumber.value)
                }
                callActionSheet.addAction(callAction)
            }
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel) { (action) in
                tableView.deselectRow(at: indexPath, animated: false)
            }
            callActionSheet.addAction(cancelAction)
            
            self.present(callActionSheet, animated: true, completion: nil)
        }
    }
}

// MARK: - Segues
extension SetupCallTransferContactsViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(segue: segue) {
        case .secondCallActive:
            // The second call is active and a subtype of SIPCallingVC, so cast the destination to it.
            let secondCallVC = segue.destination as? SecondCallViewController
            
            //secondCallVC?.call = currentCall
            secondCallVC?.firstCall = firstCall
            //secondCallVC?.phoneNumberLabelText = currentCall?.remoteNumber
            //secondCallVC?.nameLabel.text = currentCall?.displayName
            secondCallVC?.firstCallPhoneNumberLabelText = firstCallPhoneNumberLabelText
            secondCallVC?.attendedTransferSession = attendedTransferSession
            secondCallVC?.currentCallPhoneNumberLabelText = transferTargetPhoneNumber
            
        case .unwindToFirstCall:
            let callVC = segue.destination as! SIPCallingViewController
            VialerLogInfo("Unwinding to first call: \(String(describing: callVC.nameLabel.text))        \(String(describing: callVC.numberLabel.text)).")
            if let cas = callActionSheet {
                // If the action sheet is visible when unwinding to the first call, cancel it.
                cas.dismiss(animated: false, completion: nil)
            }
        }
    }
}

// MARK: - Utils
extension SetupCallTransferContactsViewController {
    func beginTransferByCalling(phoneNumber: CNPhoneNumber) {
        guard let cleanedPhoneNumber = PhoneNumberUtils.cleanPhoneNumber(phoneNumber.stringValue) else {return}
        transferTargetPhoneNumber = cleanedPhoneNumber
        
        guard let session = sip.call?.session else {return}
        attendedTransferSession = sip.beginAttendedTransfer(session: session, to: cleanedPhoneNumber)
        
        DispatchQueue.main.async { [weak self] in
            self?.performSegue(segueIdentifier: .secondCallActive)
        }
    }
}

// MARK: - KVO
extension SetupCallTransferContactsViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myContext {
            DispatchQueue.main.async { [weak self] in
                self?.updateUI()
                if let call = self?.firstCall, call.simpleState == .finished {
                    self?.performSegue(segueIdentifier: .unwindToFirstCall)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
