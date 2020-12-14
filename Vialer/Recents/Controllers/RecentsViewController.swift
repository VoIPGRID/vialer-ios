//
//  RecentsViewController.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import UIKit
import CoreData
import ContactsUI
import Contacts

class RecentsViewController: UIViewController, SegueHandler, TableViewHandler {

    @IBOutlet weak var reachabilityBar: UIView!
    
    // MARK: - Configuration
    enum SegueIdentifier: String {
        case sipCalling = "SIPCallingSegue"
        case twoStepCalling = "TwoStepCallingSegue"
        case reachabilityBar = "ReachabilityBarSegue"
    }
    enum CellIdentifier: String {
        case errorText = "CellWithErrorText"
        case recentCall = "RecentCallCell"
    }
    fileprivate struct Config {
        struct ReachabilityBar {
            static let height: CGFloat = 30.0
            static let animationDuration = 0.3
        }
    }

    // MARK: - Dependency Injection
    var user = SystemUser.current()!
    var colorsConfiguration = ColorsConfiguration.shared
    fileprivate let reachability = ReachabilityHelper.instance.reachability!
    fileprivate var notificationCenter = NotificationCenter.default
    fileprivate var reachabilityChanged: NotificationToken?
    fileprivate var sipDisabled: NotificationToken?
    fileprivate var sipChanged: NotificationToken?
    fileprivate var encryptionUsageChanged: NotificationToken?
    fileprivate var micAlert: UIAlertController

    var contactModel = ContactModel.defaultModel
    var onlyMyCalls = false
    var onlyMissedCalls = false

    private lazy var mainContext: NSManagedObjectContext = {
        return CoreDataStackHelper.instance.coreDataStack.mainContext
    }()

    private lazy var syncContext: NSManagedObjectContext = {
        return CoreDataStackHelper.instance.coreDataStack.syncContext
    }()

    fileprivate lazy var callManager: RecentCallManager = {
        let manager = RecentCallManager(managedContext: self.syncContext)
        return manager
    }()
    
    private lazy var sip: Sip = {
        (UIApplication.shared.delegate as! AppDelegate).sip
    }()

    // MARK: - Properties
    fileprivate lazy var fetchedResultController: NSFetchedResultsController<RecentCall> = {
        let fetchRequest = RecentCall.sortedFetchRequest
        fetchRequest.fetchBatchSize = 20
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.mainContext, sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        return controller
    }()

    fileprivate lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.attributedTitle = NSAttributedString(string: NSLocalizedString("Fetching the latest recent calls from the server.", comment: "Fetching the latest recent calls from the server."))
        control.addTarget(self, action: #selector(refresh(control:)), for: .valueChanged)
        return control
    }()

    // MARK: - Internal state
    var showTitleImage = false
    var phoneNumberToCall: String!
    
    // Observer that listens to logout actions.
    private var userLogout: NotificationToken? = nil

    // MARK: - Initialisation
    required init?(coder aDecoder: NSCoder) {
        micAlert = RegistrationFailedAlert.create()
        super.init(coder: aDecoder)
        setupUI()
        
        // When the user logs out, remove all calls.
        userLogout = NotificationCenter.default.addObserver(descriptor: SystemUser.logoutNotification) { _ in
            self.callManager.deleteRecentCalls()
        }
    }

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.addSubview(refreshControl)
        }
    }
    @IBOutlet weak var filterControl: UISegmentedControl! {
        didSet {
            filterControl.tintColor = colorsConfiguration.colorForKey(ColorsConfiguration.Colors.recentsFilterControlTint)
        }
    }
    @IBOutlet weak var reachabilityBarHeigthConstraint: NSLayoutConstraint!
}

// MARK: - Lifecycle
extension RecentsViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        showTitleImage = true
        setupLayout()
        reachabilityChanged = notificationCenter.addObserver(descriptor: Reachability.changed) { [weak self] _ in
            self?.updateReachabilityBar()
        }
        sipDisabled = notificationCenter.addObserver(descriptor: SystemUser.sipDisabledNotification) { [weak self] _ in
            self?.updateReachabilityBar()
        }
        sipChanged = notificationCenter.addObserver(descriptor: SystemUser.sipChangedNotification) { [weak self] _ in
            self?.updateReachabilityBar()
        }
        encryptionUsageChanged = notificationCenter.addObserver(descriptor:SystemUser.encryptionUsageNotification) { [weak self] _ in
            self?.updateReachabilityBar()
        }
        updateReachabilityBar()
        self.callManager.deleteRecentCalls()
        do {
            try self.fetchedResultController.performFetch()
        } catch let error as NSError {
            VialerLogError("Unable to fetch recents from CD: \(error) \(error.userInfo)")
            abort()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        VialerGAITracker.trackScreenForController(name: controllerName)
        setPredicate()
        refreshRecents()
        updateReachabilityBar()
    }
}

// MARK: - Actions
extension RecentsViewController {
    @IBAction func leftDrawerButtonPressed(_ sender: UIBarButtonItem) {
        mm_drawerController.toggle(.left, animated: true, completion: nil)
    }

    @IBAction func filterControlTapped(sender: UISegmentedControl) {
        onlyMyCalls = sender.selectedSegmentIndex == 1
        self.callManager.deleteRecentCalls()
        refreshRecents()
    }
    
    @IBAction func switchToggled(sender: UISwitch) {
        onlyMissedCalls = sender.isOn
        setPredicate()
        do {
            try self.fetchedResultController.performFetch()
            self.tableView.reloadData()
        } catch let error as NSError {
            VialerLogError("Error fetching recents: \(error) \(error.userInfo)")
        }
    }
}

// MARK: - Segues
extension RecentsViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(segue: segue) {
        case .twoStepCalling:
            let twoStepCallingVC = segue.destination as! TwoStepCallingViewController
            twoStepCallingVC.handlePhoneNumber(phoneNumberToCall)
        case .sipCalling:
            _ = self.sip.call(number: self.phoneNumberToCall)
        case .reachabilityBar:
            break
        }
    }
}

// MARK: - Helper functions
extension RecentsViewController {
    fileprivate func setupUI() {
        title = NSLocalizedString("Recents", comment: "Recents")
        tabBarItem.image = UIImage(asset: .tabRecent)
        tabBarItem.selectedImage = UIImage(asset: .tabRecentActive)
    }

    fileprivate func setupLayout() {
        if showTitleImage {
            navigationItem.titleView = UIImageView(image: UIImage(asset: .logo))
        } else {
            showTitleImage = true
        }
        reachabilityBarHeigthConstraint.constant = 0.0
        navigationController?.view.backgroundColor = colorsConfiguration.colorForKey(ColorsConfiguration.Colors.navigationBarBarTint)
    }

    fileprivate func call(_ number: String) {
        phoneNumberToCall = number
        if ReachabilityHelper.instance.connectionFastEnoughForVoIP() {
            VialerGAITracker.setupOutgoingSIPCallEvent()
            MicPermissionHelper.requestMicrophonePermission { startCalling in
                DispatchQueue.main.async {
                    if startCalling {
                        self.sip.register { error in
                            if (error == nil) {
                                self.performSegue(segueIdentifier: .sipCalling)
                            } else {
                                self.present(RegistrationFailedAlert.create(), animated: true, completion: nil)
                            }
                        }
                    } else {
                        self.present(self.micAlert, animated: true, completion: nil)
                    }
                }
            }
        } else if reachability.status == .notReachable {
            let alert = UIAlertController(title: NSLocalizedString("No internet connection", comment: "No internet connection"), message: NSLocalizedString("It's not possible to setup a call. Make sure you have an internet connection.", comment: "It's not possible to setup a call. Make sure you have an internet connection."), andDefaultButtonText: NSLocalizedString("Ok", comment: "Ok"))!
            present(alert, animated: true, completion: nil)
        } else {
            VialerGAITracker.setupOutgoingConnectABCallEvent()
            MicPermissionHelper.requestMicrophonePermission { startCalling in
                DispatchQueue.main.async {
                    if startCalling {
                            self.performSegue(segueIdentifier: .twoStepCalling)
                    } else {
                            self.present(self.micAlert, animated: true, completion: nil)
                    }
                }
            }
        }
    }

    fileprivate func showContactViewController(forRecent recent: RecentCall) {
        let contactViewController: CNContactViewController
        let contact: CNContact
        if recent.suppressed {
            let unknownContact = CNMutableContact()
            unknownContact.givenName = recent.displayName ?? ""
            contactViewController = CNContactViewController(forUnknownContact: unknownContact)
            contactViewController.allowsEditing = false
        } else if let recordID = recent.callerRecordID {
            contact = contactModel.getContact(for: recordID)!
            contactViewController = CNContactViewController(for: contact)
            contactViewController.title = CNContactFormatter.string(from: contact, style: .fullName)
        } else {
            let newPhoneNumber = recent.inbound ? recent.sourceNumber! : recent.destinationNumber!
            let phoneNumber = CNPhoneNumber(stringValue: newPhoneNumber)
            let phoneNumbers = CNLabeledValue<CNPhoneNumber>(label: CNLabelPhoneNumberMain, value: phoneNumber)
            let unknownContact = CNMutableContact()
            unknownContact.phoneNumbers = [phoneNumbers]
            unknownContact.givenName = ""
            contactViewController = CNContactViewController(forUnknownContact: unknownContact)
            contactViewController.title = newPhoneNumber
        }
        contactViewController.contactStore = contactModel.contactStore
        contactViewController.allowsActions = false
        contactViewController.delegate = self
        contactViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(contactViewController, animated: true)
    }

    @objc fileprivate func refresh(control: UIRefreshControl) {
        setPredicate()
        refreshRecents()
    }

    fileprivate func refreshRecents() {
        guard !callManager.reloading else {
            return
        }
        
        refreshControl.beginRefreshing()
        filterControl.isEnabled = false
        DispatchQueue.global(qos: .userInteractive).async {
            self.callManager.getLatestRecentCalls(onlyMine: self.onlyMyCalls) { fetchError in
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                    self.filterControl.isEnabled = true
                    
                    if let error = fetchError, error == .fetchNotAllowed || error == .fetchFailed {
                        if error == .fetchNotAllowed {
                            let alert = UIAlertController(title: NSLocalizedString("Not allowed", comment: "Not allowed"), message: error.localizedDescription, andDefaultButtonText: NSLocalizedString("Ok", comment: "Ok"))!
                            self.present(alert, animated: true, completion: nil)
                        }
                        self.callManager.recentsFetchFailed = true
                    }
                }
            }
        }
    }

    fileprivate func updateReachabilityBar() {
        DispatchQueue.main.async {
            if (!self.user.sipEnabled || !self.reachability.hasHighSpeed || !self.user.sipUseEncryption) {
                self.reachabilityBarHeigthConstraint.constant = Config.ReachabilityBar.height
            } else {
                self.reachabilityBarHeigthConstraint.constant = 0
            }
            UIView.animate(withDuration: Config.ReachabilityBar.animationDuration) {
                self.reachabilityBar.setNeedsUpdateConstraints()
                self.view.layoutIfNeeded()
            }
        }
    }
    
    fileprivate func setPredicate() {
        if self.onlyMissedCalls {
            // Filter the list to show only missed calls.
            self.fetchedResultController.fetchRequest.predicate = NSPredicate(format: "duration == 0 AND inbound == YES")
        } else {
            // Disable the filter on the list.
            self.fetchedResultController.fetchRequest.predicate = nil
        }
    }
}

// MARK: - CNContactViewControllerDelegate
extension RecentsViewController : CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
        guard let phoneNumber = (property.value as? CNPhoneNumber)?.stringValue else {
            return true
        }
        /**
         *  We need to return asap to prevent default action (calling with native dialer).
         *  As a workaround, we put the presenting of the new viewcontroller via a separate queue,
         *  which will immediately go back to the main thread.
         */
        DispatchQueue.main.async {
            self.call(phoneNumber)
        }
        return false
    }

    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        dismiss(animated: true, completion: nil)
        refreshRecents()
    }
}

// MARK: - UITableViewDelegate
extension RecentsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard fetchedResultController.fetchedObjects?.count != 0 else { return }
        let recent = fetchedResultController.object(at: indexPath)
        guard !recent.suppressed else { return }
        if recent.inbound {
            call(recent.sourceNumber!)
        } else {
            call(recent.destinationNumber!)
        }
    }

    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard fetchedResultController.fetchedObjects?.count != 0 else { return }
        let recent = fetchedResultController.object(at: indexPath)
        showContactViewController(forRecent: recent)
        self.tableView.deselectRow(at: indexPath, animated: false)
    }
}

// MARK: - UITableViewDataSource
extension RecentsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard callManager.recentsFetchErrorCode == nil else { return 1 }
        return max(fetchedResultController.sections?[section].numberOfObjects ?? 1, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if callManager.recentsFetchFailed {
            return failedLoadingRecentsCell(indexPath: indexPath)
        } else if fetchedResultController.fetchedObjects?.count == 0 {
            return noRecentsCell(indexPath: indexPath)
        } else {
            return recentCell(indexPath: indexPath)
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension RecentsViewController : NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // If we're showing 1 cell because of error, we need to reload the complete table.
        guard tableView(tableView, numberOfRowsInSection: 0) > 1 else { return }
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        // If we're showing 1 cell because of error, we need to reload the complete table.
        guard tableView(tableView, numberOfRowsInSection: 0) > 1 else { return }
        
        switch type {
        case .insert:
            if let newIndex = newIndexPath {
                tableView.insertRows(at: [newIndex], with: .fade)
            }
        case .update:
            if let index = indexPath {
                _ = recentCell(indexPath: index)
            }
        case .move:
            if let index = indexPath, let newIndex = newIndexPath {
                tableView.deleteRows(at: [index], with: .fade)
                tableView.insertRows(at: [newIndex], with: .fade)
            }
        case .delete:fallthrough
        default:
            if let index = indexPath {
                tableView.deleteRows(at: [index], with: .fade)
            }
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // If we're showing 1 cell because of error, we need to reload the complete table.
        if tableView(tableView, numberOfRowsInSection: 0) == 1 {
            tableView.reloadData()
        } else {
            tableView.endUpdates()
        }
    }
}

// MARK: - Cell / table configuration
extension RecentsViewController {
    fileprivate func failedLoadingRecentsCell(indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(cellIdentifier: .errorText, for: indexPath)
        switch callManager.recentsFetchErrorCode! {
        case .fetchNotAllowed:
            cell.textLabel?.text = NSLocalizedString("You are not allowed to view recent calls", comment: "You are not allowed to view recent calls")
        default:
            cell.textLabel?.text = NSLocalizedString("Could not load your recent calls", comment: "Could not load your recent calls")
        }
        return cell
    }

    fileprivate func noRecentsCell(indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(cellIdentifier: .errorText, for: indexPath)
        let noRecents: String
        if onlyMissedCalls {
            noRecents = NSLocalizedString("No missed calls", comment: "No missed calls")
        } else {
            noRecents = NSLocalizedString("No recent calls", comment: "No recent calls")
        }
        cell.textLabel?.text = noRecents
        return cell
    }

    fileprivate func recentCell(indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(cellIdentifier: .recentCall, for: indexPath) as! RecentTableViewCell
        let recent = self.fetchedResultController.object(at: indexPath)
        cell.inbound = recent.inbound
        cell.name = recent.displayName
        cell.subtitle = recent.phoneType
        cell.date = recent.callDate
        cell.missed = recent.inbound && recent.duration == 0
        return cell
    }
}
