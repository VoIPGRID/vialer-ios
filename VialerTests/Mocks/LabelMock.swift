//
//  LabelMock.swift
//  VialerTests
//
//  Created by Redmer Loen on 8/29/18.
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import UIKit
@testable import Vialer

class LabelMock: UILabel {
    var textToShow: String = ""

    override var text: String? {
        get {
            return textToShow
        }
        set { }
    }
}
