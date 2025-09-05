//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2024/10/17.
//

import Foundation

extension Array:JQFisherCompatible{}
extension JQFisher where Base == Array<Any>{}

#if canImport(UIKit)
import UIKit
#endif


public extension Array{
    ///unicode编码问题
    var unicodeDescription:String{
        return self.description.stringByReplaceUnicode
    }
}

public extension Array{
    /// 数组去重
    func jq_filterDuplicates<E: Equatable>(_ filter: (Element) -> E) -> [Element] {
        var result = [Element]()
        for value in self {
            let key = filter(value)
            if !result.map({filter($0)}).contains(key) {
                result.append(value)
            }
        }
        return result
    }

    /// 将数组转换为字典形式
    func jq_toDict(_ f:(Element)->String)->Dictionary<String,[Element]>{
        var dict = Dictionary<String,[Element]>()
        for item in self {
            if dict[f(item)] == nil {
                dict[f(item)] = [item]
            }else{
                dict[f(item)]!.append(item)
            }
        }
        return dict
    }

    /// 数组转json
    func jq_toJson1() -> String {
        if (!JSONSerialization.isValidJSONObject(self)) {
            print("无法解析出JSONString")
            return ""
        }
        let data : Data! = try? JSONSerialization.data(withJSONObject: self, options: []) as Data
        let JSONString = NSString(data:data as Data,encoding: String.Encoding.utf8.rawValue)
        return JSONString! as String
    }

    /// 从数组中从返回指定个数的元素
    ///
    /// - Parameters:
    ///   - size: 希望返回的元素个数
    ///   - noRepeat: 返回的元素是否不可以重复（默认为false，可以重复）
    func jq_sample(size: Int, noRepeat: Bool = false) -> [Element]? {
        //如果数组为空，则返回nil
        guard !isEmpty else { return nil }

        var sampleElements: [Element] = []

        //返回的元素可以重复的情况
        if !noRepeat {
            for _ in 0..<size {
                sampleElements.append(jq_sample as! Element)
            }
        }
        //返回的元素不可以重复的情况
        else{
            //先复制一个新数组
            var copy = self.map { $0 }
            for _ in 0..<size {
                //当元素不能重复时，最多只能返回原数组个数的元素
                if copy.isEmpty { break }
                let randomIndex = Int(arc4random_uniform(UInt32(copy.count)))
                let element = copy[randomIndex]
                sampleElements.append(element)
                //每取出一个元素则将其从复制出来的新数组中移除
                copy.remove(at: randomIndex)
            }
        }

        return sampleElements
    }

    func jq_max(size:Int)->[Element]{
        if self.count > size{
            return Array(self[0..<size])
        }
        return self

    }
}

extension Array{
    /// 等额平分元素
    /// - Parameters:
    ///   - array: 一维数组
    ///   - subArraySize: 平分数量
    static func jq_splitArray<T>(_ array: [T], subArraySize: Int) -> [[T]] {
        var result: [[T]] = []

        for i in stride(from: 0, to: array.count, by: subArraySize) {
            let value = array[i..<Swift.min(i + subArraySize,array.count)]
            let chunk = Array<T>(value)
            result.append(chunk)
        }

        return result
    }

    /// 根据数量，生成合适的行数和列数，适用于UICollectionView
    /// - Parameter count:
    static func jq_salmulateCell(_ count:Int)->(Int,Int)?{

        let sqr = Int(ceil(sqrt(Double(count))))

        var tempInt = Array<(Int,Int)>()

        for i in 1...10{
            for j in 1...10{
                if i * j >= count && (i == sqr || j == sqr){
                    tempInt.append((i,j))
                }
            }
        }

        let a = tempInt.first?.0
        let b = tempInt.first?.1

        if a == nil || b == nil{return nil}

        if a! == b! || a! > b!{
            return (a!,b!)
        }else{
            return (b!,a!)
        }
    }
}
