//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2024/10/17.
//

import Foundation

extension Int:JQFisherCompatible{}

public extension Int{
    static func randomValue<T: BinaryInteger>(in range: ClosedRange<T>) -> T {
        let length = range.upperBound - range.lowerBound + 1
        let random = arc4random_uniform(UInt32(length))
        return T(random) + range.lowerBound
    }
}

extension JQFisher where Base == Int{
    ///分转元
    func centsToElement() -> String {
        return String(format: "%.2f",CGFloat(self.base) / 100)
    }
    ///元转分
    func elementToCents() -> String {
        return String(format: "%.2f",CGFloat(self.base) * 100)
    }

    ///单位转换
    func unit()->String{
        if self.base > 0 && self.base < 1000{
            return String(format: "%ld", self.base)
        }else if self.base >= 1000 && self.base < 10000 {
            if String(format: "%.2lfK", CGFloat(Double(self.base)/1000.0)).contains(".00") {
                return String(format: "%.lfK", CGFloat(Double(self.base)/1000.0))
            }else{
                return String(format: "%.2lfK", CGFloat(Double(self.base)/1000.0))
            }
        }else if self.base >= 10000{
            if String(format: "%.2lfW", CGFloat(Double(self.base)/10000.0)).contains(".00") {
                return String(format: "%.lfW", CGFloat(Double(self.base)/10000.0))
            }else{
                return String(format: "%.2lfW", CGFloat(Double(self.base)/10000.0))
            }
        }else{
            return "0"
        }
    }

    /// 转换为中文展示
    var cn: String {
        get {
            if self.base == 0 {
                return "零"
            }
            let zhNumbers = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
            let units = ["", "十", "百", "千", "万", "十", "百", "千", "亿", "十","百","千"]
            var cn = ""
            var currentNum = 0
            var beforeNum = 0
            let intLength = Int(floor(log10(Double(self.base))))
            for index in 0...intLength {
                currentNum = self.base/Int(pow(10.0,Double(index)))%10
                if index == 0{
                    if currentNum != 0 {
                        cn = zhNumbers[currentNum]
                        continue
                    }
                } else {
                    beforeNum = self.base/Int(pow(10.0,Double(index-1)))%10
                }
                if [1,2,3,5,6,7,9,10,11].contains(index) {
                    if currentNum == 1 && [1,5,9].contains(index) && index == intLength { // 处理一开头的含十单位
                        cn = units[index] + cn
                    } else if currentNum != 0 {
                        cn = zhNumbers[currentNum] + units[index] + cn
                    } else if beforeNum != 0 {
                        cn = zhNumbers[currentNum] + cn
                    }
                    continue
                }
                if [4,8,12].contains(index) {
                    cn = units[index] + cn
                    if (beforeNum != 0 && currentNum == 0) || currentNum != 0 {
                        cn = zhNumbers[currentNum] + cn
                    }
                }
            }
            return cn
        }
    }


    /// 转换为中文展示-金融货币单位
    var cnCoin: String {
        get {
            if self.base == 0 {
                return "零"
            }
            let zhNumbers = ["零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖"]
            let units = ["", "拾", "佰", "仟", "万", "拾", "百", "千", "亿", "拾","佰","仟"]
            var cn = ""
            var currentNum = 0
            var beforeNum = 0
            let intLength = Int(floor(log10(Double(self.base))))
            for index in 0...intLength {
                currentNum = self.base/Int(pow(10.0,Double(index)))%10
                if index == 0{
                    if currentNum != 0 {
                        cn = zhNumbers[currentNum]
                        continue
                    }
                } else {
                    beforeNum = self.base/Int(pow(10.0,Double(index-1)))%10
                }
                if [1,2,3,5,6,7,9,10,11].contains(index) {
                    if currentNum == 1 && [1,5,9].contains(index) && index == intLength { // 处理一开头的含十单位
                        cn = units[index] + cn
                    } else if currentNum != 0 {
                        cn = zhNumbers[currentNum] + units[index] + cn
                    } else if beforeNum != 0 {
                        cn = zhNumbers[currentNum] + cn
                    }
                    continue
                }
                if [4,8,12].contains(index) {
                    cn = units[index] + cn
                    if (beforeNum != 0 && currentNum == 0) || currentNum != 0 {
                        cn = zhNumbers[currentNum] + cn
                    }
                }
            }
            return cn
        }
    }
}
