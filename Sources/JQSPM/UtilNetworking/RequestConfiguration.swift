//
//  RequestConfiguration.swift
//  UtilNetworking
//
//  Created by baipayne on 2025/3/18.
//

import Foundation

/// The components of an HTTP request
public protocol RequestConfiguration {
    var method: UtilHTTPMethod { get }
    var path: String { get }
    var params: [URLQueryItem] { get }
    var headers: [String: String]? { get }
    var httpBody: Data? { get throws }
    /// This property assumes the query item names and values are already correctly percent-encoded.
    var percentEncodedParams: [URLQueryItem] { get }
    var timeoutInterval: TimeInterval { get }
}

public extension RequestConfiguration {
    var params: [URLQueryItem] { [] }
    var headers: [String: String]? { nil }
    var httpBody: Data? { nil }
    var percentEncodedParams: [URLQueryItem] { [] }
    var timeoutInterval: TimeInterval { 20 }
}
