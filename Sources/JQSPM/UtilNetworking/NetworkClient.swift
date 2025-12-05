//
//  File.swift
//  UtilNetworking
//
//  Created by baipayne on 2025/3/18.
//

import Foundation
import QuartzCore
import JQSPM

/// A client protocol for sending URL requests
public protocol NetworkClient {
    /// The `URLSession` that will be used to make the request
    var urlSession: URLSession { get }
    /// support http status code, default is [200]
    var supportStatusCodes: [Int] { get }
    /// Host url string
    var hostUrl: String { get }
    /// Custom Headers for request
    var customHeaders: [String: String]? { get }
    /// Create and configure the URL request
    func urlRequest(for configuration: RequestConfiguration) async throws -> URLRequest
    /// Sends a URL request and returns the raw data and reponse
    func dataTaskWithHTTPResponse(configuration: RequestConfiguration,
                                  acceptableStatusCodes: [Int]) async throws -> (Data, HTTPURLResponse)
}

public actor NetworkClientLogger {
    nonisolated(unsafe) static let logger = JQLog.instance(
        enable: true
    )
}

public extension NetworkClient {
    
    var urlSession: URLSession { URLSession.shared }
    
    var supportStatusCodes: [Int] { Array(200..<201) }
    
    var customHeaders: [String: String]? { return nil }

    func urlRequest(for configuration: RequestConfiguration) async throws -> URLRequest {
        guard let url = URL(string: hostUrl) else {
            throw NetworkClientError.internalError(message: "can't convert to URL with: \(hostUrl)")
        }

        var urlComponents = URLComponents(url: url.appendingPathComponent(configuration.path), resolvingAgainstBaseURL: false)
        
        if !configuration.params.isEmpty {
            urlComponents?.queryItems = configuration.params
        }
        
        guard let url = urlComponents?.url else {
            throw NetworkClientError.internalError(message: "URL construction failed")
        }
        
        // 创建 URLRequest
        var request = URLRequest(url: url)
        // 设置请求方法
        request.httpMethod = configuration.method.rawValue
        // 设置请求体
        request.httpBody = try configuration.httpBody
        // 设置等待响应时间
        request.timeoutInterval = configuration.timeoutInterval

        // 客户端请求头
        if let customHeaders {
            customHeaders.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        // 设置请求头
        if let headers = configuration.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return request
    }
    
    func dataTask(configuration: RequestConfiguration) async throws -> Data {
        try await dataTask(
            configuration: configuration,
            acceptableStatusCodes: supportStatusCodes)
    }

    func dataTask(configuration: RequestConfiguration,
                  acceptableStatusCodes: [Int]) async throws -> Data {
        let (data, _) = try await dataTaskWithHTTPResponse(
            configuration: configuration,
            acceptableStatusCodes: acceptableStatusCodes)
        return data
    }

    func dataTaskWithHTTPResponse(configuration: RequestConfiguration) async throws -> (Data, HTTPURLResponse) {
        try await dataTaskWithHTTPResponse(
            configuration: configuration,
            acceptableStatusCodes: supportStatusCodes)
    }

    func dataTaskWithHTTPResponse(configuration: RequestConfiguration,
                                  acceptableStatusCodes: [Int]) async throws -> (Data, HTTPURLResponse) {

        let urlRequest = try await urlRequest(for: configuration)
        let start = CACurrentMediaTime()
        let reqId = UUID().uuidString
        NetworkClientLogger.logger.debug("<\(reqId)> Request: \(urlRequest.methodStr) \(urlRequest.urlString)\nHeaders: \(urlRequest.headerStr)\nHttpBody: \(urlRequest.httpBodyStr)")
        do {
            let result: (Data, URLResponse)
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                result = try await urlSession.data(for: urlRequest, delegate: nil)
            } else {
                result = try await withCheckedThrowingContinuation { continuation in
                    let task = urlSession.dataTask(with: urlRequest, completionHandler: { data, response, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }

                        guard let data = data, let response = response else {
                            let error = NetworkClientError.invalidResponse(data: data, urlResponse: response)
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        continuation.resume(returning: (data, response))
                    })
                    task.resume()
                }
            }
            
            let (data, urlResponse) = result
            
            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                throw NetworkClientError.invalidResponse(data: data, urlResponse: urlResponse)
            }

            if 200..<300 ~= httpResponse.statusCode {
                NetworkClientLogger.logger.debug("<\(reqId)> Response: \(httpResponse.statusCode) \(urlRequest.urlString)  \(String(format: "%.4fs", CACurrentMediaTime() - start))\nData: \(String(data: data, encoding: .utf8) ?? "null")")
            } else {
                NetworkClientLogger.logger.error("<\(reqId)> Response: \(httpResponse.statusCode) \(urlRequest.urlString)  \(String(format: "%.4fs", CACurrentMediaTime() - start))\nData: \(String(data: data, encoding: .utf8) ?? "null")")
            }
    
            guard acceptableStatusCodes.contains(httpResponse.statusCode) else {
                throw NetworkClientError.invalidStatusCode(data: data, httpUrlResponse: httpResponse)
            }

            return (data, httpResponse)
        } catch {
            NetworkClientLogger.logger.error("<\(reqId)> Request Failed: \(urlRequest.urlString) \(error)")
            throw error
        }
    }

    func jsonTask<T: Decodable>(
        configuration: RequestConfiguration) async throws -> T {
        try await jsonTask(configuration: configuration,
                           acceptableStatusCodes: supportStatusCodes,
                           jsonDecoder: JSONDecoder())
    }

    func jsonTask<T: Decodable>(
        configuration: RequestConfiguration,
        acceptableStatusCodes: [Int]) async throws -> T {
        try await jsonTask(configuration: configuration,
                           acceptableStatusCodes: acceptableStatusCodes,
                           jsonDecoder: JSONDecoder())
    }

    func jsonTask<T: Decodable>(
        configuration: RequestConfiguration,
        acceptableStatusCodes: [Int],
        jsonDecoder: JSONDecoder) async throws -> T {
        let data = try await dataTask(configuration: configuration, acceptableStatusCodes: acceptableStatusCodes)
        return try jsonDecoder.decode(T.self, from: data)
    }
}

private extension URLRequest {
    var urlString: String {
        url?.absoluteString ?? "null"
    }
    
    var methodStr: String {
        httpMethod ?? "GET"
    }
    
    var headerStr: String {
        allHTTPHeaderFields?.description ?? "null"
    }
    
    var httpBodyStr: String {
        guard let data = httpBody else {
            return "null"
        }
        return String(data: data, encoding: .utf8) ?? "null"
    }
}
