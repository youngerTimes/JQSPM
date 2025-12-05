//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/11/11.
//

import Foundation


//自定义的全局Actor
@globalActor
public struct JQGlobalAdder{
    public actor JQGlobalActor{}
    public static let shared = JQGlobalActor()
}
