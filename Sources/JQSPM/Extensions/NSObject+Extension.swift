//
//  NSObject+JQExtension.swift
//  JQTools
//
//  Created by 无故事王国 on 2021/2/8.
//

import Foundation

public extension NSObject{
    func jq_mirror(){
        let hMirror  = Mirror(reflecting: self)
        print("==================\(hMirror.subjectType)======================")
        print("-->\(hMirror.subjectType)")
        for case let (label?,value) in hMirror.children {
            print("属性：\(label)     值：\(value)")
        }
        print("==================\(hMirror.subjectType)======================")
    }

    class var nameOfClass: String {
        return NSStringFromClass(self).components(separatedBy: ".").last! as String
    }

    // 用于获取 cell 的 reuse identifier
    class var identifier: String {
        return String(format: "%@_identifier", self.nameOfClass)
    }
}
