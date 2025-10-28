//
//  JQ_Def.swift
//  JQSPM
//
//  Created by 无故事王国 on 2024/11/26.
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import OSLog

// https://www.jianshu.com/p/3c1dddb0e5b0

#if canImport(UIKit)

@MainActor public let JQ_ScreenWidth:Double = {
    return UIScreen.main.bounds.width
}()

@MainActor public let JQ_ScreenHeight:Double = {
    return UIScreen.main.bounds.height
}()

@MainActor public let JQ_ScreenScale: CGFloat = {
    return UIScreen.main.scale
}()

@MainActor public var JQ_NavH:Double {
    get{
        if #available(iOS 13.0, *) {
            let manager = UIApplication.shared.windows.first?.windowScene?.statusBarManager
            return Double( manager?.statusBarFrame.size.height ?? 0)
        } else {
            return UIApplication.shared.statusBarFrame.size.height
        }
    }
}
#else
// macOS默认值
public var JQ_NavH:Double {
    return 0.0
}
#endif


public final class JQFisher<Base>{
    public let base:Base
    init(base: Base) {
        self.base = base
    }
}

public protocol JQFisherCompatible{
    associatedtype CompatibleType
    var jq:CompatibleType{get}
}

public extension JQFisherCompatible{
    var jq:JQFisher<Self>{
        return JQFisher(base: self)
    }
}

#if canImport(UIKit)
extension UIImage:JQFisherCompatible{}
#endif






