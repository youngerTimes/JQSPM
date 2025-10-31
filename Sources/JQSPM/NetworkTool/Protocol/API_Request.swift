//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/10/29.
//

import Alamofire
import Foundation

public typealias APIBearerRequest = APIRequest & APIRequestBearerAuthorizable


public protocol APIRequestBearerAuthorizable {
    var accessToken: String? { get }
}

extension APIRequestBearerAuthorizable{
    var accessToken: String? {return nil}
}

public protocol APIRequestBasicAuthorizable {
    var username: String { get }
    var password: String { get }
}


public protocol APIRequest{
    var uri: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders? { get }
    var parameters: Encodable? { set get }
    var parameterEncoding: ParameterEncoding { get }
    var queue:DispatchQueue {get}
}

public extension APIRequest{
    var queue:DispatchQueue{return .main}
    var headers:HTTPHeaders?{return nil}
    var method: HTTPMethod { return .get}
    var parameters:Encodable? { return nil }
    var parameterEncoding: ParameterEncoding {
        if method == .get {
            return URLEncoding.default
        }
        return JSONEncoding.default
    }
}
