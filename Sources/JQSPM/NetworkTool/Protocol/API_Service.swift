//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/10/29.
//

import Foundation
import Alamofire

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol APIBaseService:Sendable{
    var host:String{get}
    var timeoutInterval:TimeInterval{get}
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension APIBaseService{
    var timeoutInterval:TimeInterval{return 20}
}

@available(macOS 10.15.0, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension APIBaseService {

    func sendRequest<R: APIRequest,S:APIResponse>(_ req: R, res:S.Type) async -> Result<S,APIError>{
        var parameters:[String: any Any & Sendable]?
        if let params = req.parameters{
            do{
                let json = try JSONEncoder().encode(params)
                let value = try JSONSerialization.jsonObject(with: json) as? [String: any Any & Sendable]
                parameters = value
            }catch _{
                return .failure(JSONEncoderERROR)
            }
        }

        let url = host + req.uri

        let result = await withCheckedContinuation { t in
             AF.request(url, method: req.method, parameters: parameters, headers: req.headers, interceptor: nil, requestModifier: {
                 $0.timeoutInterval = self.timeoutInterval
            }).validate().responseDecodable(of: res, queue: req.queue) { value in
                t.resume(returning: value)
            }
        }

        switch result.result{
        case .success(let result):
            return .success(result)
        case .failure(let error):
            return .failure(APIError(code: error.responseCode ?? 0, message: error.localizedDescription))
        }
    }

    func sendBearerRequest<R: APIBearerRequest,S:APIResponse>(_ req: R, res:S.Type) async -> Result<S,APIError>{
        if req.accessToken?.isEmpty ?? true{
            return .failure(JSONEncoderEmptyToken)
        }
        return await sendRequest(req, res: res)
    }


    func cancelAllRequest(){
        AF.cancelAllRequests(completingOnQueue: .main, completion: nil)
    }
}
