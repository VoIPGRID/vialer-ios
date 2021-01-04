//
// Created by Jeremy Norman on 12/11/2020.
// Copyright (c) 2020 VoIPGRID. All rights reserved.
//

import Foundation

@objc class RegistrationFailedAlert: UIAlertController {

    @objc static func create() -> UIAlertController {
        let alert = UIAlertController(title: NSLocalizedString("Failed to setup call", comment: ""), message: NSLocalizedString("Check your network status.", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        return alert
    }
}
