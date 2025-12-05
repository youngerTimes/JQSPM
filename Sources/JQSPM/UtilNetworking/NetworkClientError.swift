//
//  NetworkClientError.swift
//  UtilNetworking
//
//  Created by baipayne on 2025/3/18.
//

import Foundation

public enum NetworkClientError: Error {
    case invalidResponse(data: Data?, urlResponse: URLResponse?)
    case invalidStatusCode(data: Data?, httpUrlResponse: HTTPURLResponse)
    case internalError(message: String)
}
