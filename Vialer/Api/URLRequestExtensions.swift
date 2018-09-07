//
//  URLRequestExtensions.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation

extension URLRequest {
    init<A>(resource: Resource<A>, basicAuth: String) {
        var url = URL(string: UrlsConfiguration.shared.apiUrl())!
        if let params = resource.parameters?.stringFromHttpParameters() {
            url = URL(string: "\(url)\(resource.path)?\(params)")!
        }
        self.init(url: url)
        setValue("Basic \(basicAuth)", forHTTPHeaderField: "Authorization")
    }
}

/// Extensions source: http://stackoverflow.com/a/27724627/5516291
fileprivate extension Dictionary {
    /// Build string representation of HTTP parameter dictionary of keys and objects
    ///
    /// This percent escapes in compliance with RFC 3986
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    ///  - Returns: String representation in the form of key1=value1&key2=value2 where the keys and values are percent escaped
    func stringFromHttpParameters() -> String {
        let parameters = self.map { (key, value) -> String in
            let percentEscapedKey = (key as! String).addingPercentEncodingForURLQueryValue()!
            let percentEscapedValue = "\(value)".addingPercentEncodingForURLQueryValue()!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        return parameters.joined(separator: "&")
    }
}

fileprivate extension String {
    /// Percent escapes values to be added to a URL query as specified in RFC 3986
    ///
    /// This percent-escapes all characters besides the alphanumeric character set and "-", ".", "_", and "~".
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// - Returns: percent-escaped string.
    func addingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
}
