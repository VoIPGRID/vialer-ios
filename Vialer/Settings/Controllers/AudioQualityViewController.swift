//
//  AudioQualityViewController.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import UIKit

@objc public enum AudioQuality: Int, EnumHelper {
    case low = 0, high

    var descriprtion: String {
        switch self {
        case .low:
            return NSLocalizedString("Standard audio", comment: "Standard audio")
        case .high:
            return NSLocalizedString("Higher quality audio", comment: "Higher quality audio")
        }
    }

    var explanation: String {
        switch self {
        case .low:
            return NSLocalizedString("Low bandwidth", comment: "Low bandwidth")
        case .high:
            return NSLocalizedString("Clearer audio - possible higher bandwidth", comment: "Clearer audio - possible higher bandwidth")
        }
    }
}

class AudioQualityViewController: UIViewController, TableViewHandler {

    enum CellIdentifier: String {
        case audioQuality = "AudioQualityCell"
    }

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        sender.isEnabled = false

        let audioQualityToStore = selectedIndexPath?.row ?? 0
        let audioQuality = SystemUser.current()?.currentAudioQuality

        if audioQualityToStore == audioQuality {
            self.navigationController?.popViewController(animated: true)
            return
        }

        DispatchQueue.global(qos: .background).async {
            SystemUser.current()?.updateUseOpus(audioQualityToStore, withCompletion: { (success, error) in
                if success {
                    SystemUser.current()?.currentAudioQuality = audioQualityToStore
                    if success {
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        let alertController = UIAlertController(title: NSLocalizedString("Could not save audio settings", comment: "Could not save audio settings"),
                                                                message: NSLocalizedString("An error occured when saving your changes. Please try again.", comment: "An error occured when saving your changes. Please try again."),
                                                                preferredStyle: .alert)

                        let okButton = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                            let oldCell = self.tableView.cellForRow(at: self.selectedIndexPath!)
                            oldCell?.accessoryType = .none
                            self.tableView.reloadData()
                        })

                        alertController.addAction(okButton)

                        self.present(alertController, animated: true, completion: nil)
                    }
                } else {
                    let alertController = UIAlertController(title: NSLocalizedString("Could not save audio settings", comment: "Could not save audio settings"),
                                                            message: NSLocalizedString("An error occured when saving your changes. Please try again.", comment: "An error occured when saving your changes. Please try again."),
                                                            preferredStyle: .alert)


                    let okButton = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        let oldCell = self.tableView.cellForRow(at: self.selectedIndexPath!)
                        oldCell?.accessoryType = .none
                        self.tableView.reloadData()
                    })

                    alertController.addAction(okButton)

                    self.present(alertController, animated: true, completion: nil)
                }
                sender.isEnabled = true
            })
        }
    }

    private var selectedIndexPath: IndexPath?
    private var previousSelectedIndexPath: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension AudioQualityViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AudioQuality.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(cellIdentifier: .audioQuality, for: indexPath)
        let audioQuality = AudioQuality.init(rawValue: SystemUser.current()?.currentAudioQuality ?? 0)!

        if indexPath.row == AudioQuality.low.rawValue {
            cell.textLabel?.text = AudioQuality.low.descriprtion
            cell.detailTextLabel?.text = AudioQuality.low.explanation

            if audioQuality == AudioQuality.low {
                cell.accessoryType = .checkmark
                selectedIndexPath = indexPath
            }
        } else if indexPath.row == AudioQuality.high.rawValue {
            cell.textLabel?.text = AudioQuality.high.descriprtion
            cell.detailTextLabel?.text = AudioQuality.high.explanation
            if audioQuality == AudioQuality.high {
                selectedIndexPath = indexPath
                cell.accessoryType = .checkmark
            }
        }
        return cell
    }
}

extension AudioQualityViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath == selectedIndexPath {
            return
        }

        let oldCell = tableView.cellForRow(at: selectedIndexPath!)
        oldCell?.accessoryType = .none

        let newCell = tableView.cellForRow(at: indexPath)
        newCell?.accessoryType = .checkmark

        selectedIndexPath = indexPath

    }
}
