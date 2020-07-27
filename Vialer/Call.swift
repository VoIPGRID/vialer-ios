//
// Created by Jeremy Norman on 27/07/2020.
// Copyright (c) 2020 VoIPGRID. All rights reserved.
//

import Foundation
import PhoneLib

class Call {

    let session: Session
    let direction: Direction
    let uuid: UUID

    init(session: Session, direction: Direction) {
        self.direction = direction
        self.uuid = UUID.init()
        self.session = session
    }
}

enum Direction {
    case outbound
    case inbound
}
