//
// Created by Jeremy Norman on 12/11/2020.
// Copyright (c) 2020 VoIPGRID. All rights reserved.
//

import Foundation

class RegistrationFailedAlert: UIAlertController {

    static func create() -> UIAlertController {
        let alert = UIAlertController(title: nil, message: NSLocalizedString("Failed to setup call", comment: "Failed to setup call"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        return alert
    }
}
