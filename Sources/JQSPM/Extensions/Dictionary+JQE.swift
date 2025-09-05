//
//  Dictionary+Extension.swift
//  Alamofire
//
//  Created by 无故事王国 on 2020/5/14.
//

import Foundation
//#if canImport(UIKIt)
extension Dictionary:JQFisherCompatible{}
extension JQFisher where Base == Dictionary<String, Any>{}

public extension JQFisher where Base == Dictionary<String,Any>{

    /// 字典转字符串
    func toString() -> String?{
        let data = try? JSONSerialization.data(withJSONObject: self, options: [])
        let str = String(data: data!, encoding: String.Encoding.utf8)
        return str
    }

    /// 排序Key并转字符串
    func toSortedJSONString(prettyPrinted: Bool = false) -> String? {
        // 按 key 排序（转换为字符串后比较）
        let sortedDict = self.base.sorted { lhs, rhs in
            let key1 = String(describing: lhs.key)
            let key2 = String(describing: rhs.key)
            return key1 < key2
        }

        // 转换为可序列化的格式
        let serializedDict = Dictionary(uniqueKeysWithValues: sortedDict)

        do {
            // 转换为 JSON 数据
            let options: JSONSerialization.WritingOptions = prettyPrinted ? .prettyPrinted : []
            let jsonData = try JSONSerialization.data(withJSONObject: serializedDict, options: options)

            // 转换为字符串
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print("JSON serialization error: \(error)")
        }
        return nil
    }

    func toData() -> Data? {
        if !JSONSerialization.isValidJSONObject(self) {
            return nil
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: [])
            return data
        } catch _ {
            return nil
        }
    }

    func base64String()->String{
        return  ((toData()?.base64EncodedString() ?? "")).replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

}
public extension Dictionary where Value: Equatable {

    /// 根据值返回Key
    func jq_key(forValue value: Value) -> Key? {
        return first { $0.1 == value }?.0
    }
}

//#endif
