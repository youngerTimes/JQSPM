//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/10/29.
//

import Foundation

public protocol APIResponse: Codable,Sendable { }
extension Array: APIResponse where Element: APIResponse { }
extension Set: APIResponse where Element: APIResponse { }
