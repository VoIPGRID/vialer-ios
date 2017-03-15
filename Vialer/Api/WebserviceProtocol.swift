//
//  WebserviceProtocol.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation


protocol WebserviceProtocol {
    func load<A>(resource: Resource<A>, completion: @escaping (Result<A?>) -> ())
}
