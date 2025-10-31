//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/10/30.
//

import Foundation
public struct APIError: Error {
    let message: String?
    let code:Int?

    init(code:Int,message: String) {
        self.message = message
        self.code = code
    }
}

public let JSONEncoderERROR = APIError(code: 1000, message: "JSON参数错误")
public let JSONEncoderEmptyToken = APIError(code: 1001, message: "Token为空")

