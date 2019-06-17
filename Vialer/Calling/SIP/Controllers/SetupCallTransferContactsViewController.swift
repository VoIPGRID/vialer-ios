import Foundation

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
        if call.callState == .disconnected {
            firstCallStatusLabel?.text = NSLocalizedString("Disconnected", comment: "Disconnected phone state")
        } else {
            firstCallStatusLabel?.text = NSLocalizedString("On hold", comment: "On hold")
        }
    }

    @IBAction func cancelPressed(_ sender: AnyObject) {
        guard let call = currentCall else {
            performSegue(segueIdentifier: .unwindToFirstCall)
            return
        }
        callManager.end(call) { error in
            if error != nil {
                VialerLogError("Could not hangup call: \(String(describing: error))")
            } else {
                self.performSegue(segueIdentifier: .unwindToFirstCall)
            }

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
        
        VialerGAITracker.trackScreenForController(name: controllerName)

        firstCall?.addObserver(self, forKeyPath: "callState", options: .new, context: &myContext)

        updateUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        firstCall?.removeObserver(self, forKeyPath: "callState")
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
            makeCall(phoneNumber: contact.phoneNumbers[0].value)
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
                    self.makeCall(phoneNumber: phoneNumber.value)
                }
                callActionSheet.addAction(callAction)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
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
            let secondCallVC = segue.destination as! SecondCallViewController
            secondCallVC.activeCall = currentCall
            secondCallVC.firstCall = firstCall
            secondCallVC.phoneNumberLabelText = currentCall?.numberToCall
            secondCallVC.firstCallPhoneNumberLabelText = firstCallPhoneNumberLabelText
        case .unwindToFirstCall:
            let callVC = segue.destination as! SIPCallingViewController
            if let call = currentCall, call.callState != .null && call.callState != .disconnected {
                callVC.activeCall = call
            } else if let call = firstCall, call.callState != .null && call.callState != .disconnected {
                callVC.activeCall = call
            }
            if let cas = callActionSheet {
                // If the action sheet is visable when unwinding to the first call, cancel it.
                cas.dismiss(animated: false, completion: nil)
            }
        }
    }
}

// MARK: - Utils
extension SetupCallTransferContactsViewController {
    func makeCall(phoneNumber: CNPhoneNumber) {
        let cleanedPhoneNumber = PhoneNumberUtils.cleanPhoneNumber(phoneNumber.stringValue)!
        
        callManager.startCall(toNumber: cleanedPhoneNumber, for: firstCall!.account!) { call, error in
            DispatchQueue.main.async { [weak self] in
                self?.currentCall = call
                self?.performSegue(segueIdentifier: .secondCallActive)
            }
        }
    }
}

// MARK: - KVO
extension SetupCallTransferContactsViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myContext {
            DispatchQueue.main.async { [weak self] in
                self?.updateUI()
                if let call = self?.firstCall, call.callState == .disconnected {
                    self?.performSegue(segueIdentifier: .unwindToFirstCall)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
