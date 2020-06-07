//
// Created by Jeremy Norman on 06/06/2020.
// Copyright (c) 2020 VoIPGRID. All rights reserved.
//

import Foundation

extension VialerSIPLib {

    /**
        Check to see if there is any active call currently in the sip lib.
    */
    public func hasActiveCall() -> Bool {
        let vsl = VialerSIPLib.sharedInstance()

        guard let account = vsl.firstAccount() else {
            return false
        }

        return vsl.callManager.firstActiveCall(for: account) != nil
    }
}