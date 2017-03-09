//
//  UITableView.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation

protocol TableViewHandler {
    associatedtype CellIdentifier: RawRepresentable
    weak var tableView: UITableView! { get }
}

extension TableViewHandler where Self : UIViewController, CellIdentifier.RawValue == String {
    func dequeueReusableCell(cellIdentifier identifier: CellIdentifier, for indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: identifier.rawValue, for: indexPath)
    }
}
