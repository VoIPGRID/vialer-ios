//
//  AvailabilityViewController.swift
//  Vialer
//
//  Created by Chris Kontos on 09/10/2018.
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

@objc protocol AvailabilityViewControllerDelegate: NSObjectProtocol {
    func availabilityViewController(_ controller: AvailabilityViewController?, availabilityHasChanged availabilityOptions: [Any]?)
}

private let AvailabilityAddFixedDestinationSegue = "AddFixedDestinationSegue"
private let AvailabilityViewControllerAddFixedDestinationPageURLWithVariableForClient = "/client/%@/fixeddestination/add/"

@objc class AvailabilityViewController: UITableViewController {
    private var lastSelected: IndexPath?
    private var availabilityModel: AvailabilityModel?

    override func awakeFromNib() {
        super.awakeFromNib() //orp: is this needed here? no super class exists
        refreshControl?.attributedTitle = NSAttributedString(string: NSLocalizedString("Loading availability options...", comment: ""))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        VialerGAITracker.trackScreenForController(name: NSStringFromClass(type(of: self).self))
        
        refreshControl?.beginRefreshing()
        tableView.setContentOffset(CGPoint(x: 0, y: -(refreshControl?.frame.size.height ?? 0.0)), animated: true)
        if let unwrappedRefreshControl = refreshControl {
            loadUserDestinations(unwrappedRefreshControl)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tintColor = Configuration.default().colorConfiguration.color(forKey: ConfigurationAvailabilityTableViewTintColor)
    }
    
    func availabilityModel() -> AvailabilityModel? {
        if availabilityModel == nil {
            availabilityModel = AvailabilityModel()
        }
        return availabilityModel
    }
    
    @IBAction func loadUserDestinations(_ sender: UIRefreshControl) {
        availabilityModel.getUserDestinations({ localizedErrorString in
            if localizedErrorString != nil {
                self.present(UIAlertController(title: NSLocalizedString("Error", comment: ""), message: localizedErrorString, andDefaultButtonText: NSLocalizedString("Ok", comment: "")), animated: true)
            } else {
                self.tableView.reloadData()
            }
            self.refreshControl?.endRefreshing()
        })

    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availabilityModel.availabilityOptions.count()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let DefaultCellIdentifier = "AvailabilityTableViewDefaultCell"
        let availabilityDict = availabilityModel.availabilityOptions[indexPath.row]
        
        //orp let cell: UITableViewCell? = self.tableView.dequeueReusableCell(withIdentifier: DefaultCellIdentifier)
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: DefaultCellIdentifier) else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: DefaultCellIdentifier)
        }
        if (availabilityDict[AvailabilityModelPhoneNumberKey] == 0) {
            cell?.textLabel?.text = availabilityDict[AvailabilityModelDescription] as? String
        } else {
            var phoneNumber = "\((availabilityDict[AvailabilityModelPhoneNumberKey] as? String ?? ""))"
            if phoneNumber.count > 5 {
                phoneNumber = "+" + (phoneNumber)
            }
            cell?.textLabel?.text = "\(phoneNumber) / \(availabilityDict[AvailabilityModelDescription])"
        }
        if (availabilityDict[AvailabilityModelSelected] == (1)) {
            cell.accessoryType = .checkmark
            lastSelected = indexPath
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let lastSelectedUnwrapped = lastSelected {
            tableView.cellForRow(at: lastSelectedUnwrapped)?.accessoryType = .none
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        
        if indexPath.row >= availabilityModel.availabilityOptions.count() {
            return
        }
        lastSelected = indexPath
        
        SVProgressHUD.show(withStatus: NSLocalizedString("Saving availability...", comment: ""))
        availabilityModel.saveUserDestination(lastSelected.row, withCompletion: { localizedErrorString in
            SVProgressHUD.dismiss()
            if localizedErrorString != nil {
                var alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: localizedErrorString, andDefaultButtonText: NSLocalizedString("Ok", comment: ""))
                self.present(alert, animated: true)
            } else {
                self.delegate.availabilityViewController(self, availabilityHasChanged: self.availabilityModel.availabilityOptions)
                self.parent?.dismiss(animated: true)
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == AvailabilityAddFixedDestinationSegue) {
            if (segue.destination is VialerWebViewController) {
                let webController = segue.destination as? VialerWebViewController
                
                VialerGAITracker.trackScreenForController(name: VialerGAITracker.GAAddFixedDestinationWebViewTrackingName())
                webController?.title = NSLocalizedString("Add destination", comment: "")
                let nextURL = String(format: AvailabilityViewControllerAddFixedDestinationPageURLWithVariableForClient, SystemUser.current().clientID)
                webController?.nextUrl(nextURL)
            } else {
                VialerLogWarning("Could not segue, destinationViewController is not a \"VialerWebViewController\"")
            }
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        parent?.dismiss(animated: true)
    }
}
