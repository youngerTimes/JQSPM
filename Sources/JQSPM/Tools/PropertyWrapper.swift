//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/11/26.
//

import Foundation

/// 限制输入范围
/**
 struct Solution {
 @Clamping(0...14) var pH: Double = 7.0
 }
 */
@propertyWrapper
public struct Clamping<Value: Comparable> {
    private var value: Value
    private let range: ClosedRange<Value>

    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.value = range.clamp(wrappedValue)
    }

    public var wrappedValue: Value {
        get { value }
        set { value = range.clamp(newValue) }
    }
}

// 为 ClosedRange 添加 clamp 方法
public extension ClosedRange {
    func clamp(_ value: Bound) -> Bound {
        return Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
