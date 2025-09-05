//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2024/10/17.
//

import Foundation

extension Double:JQFisherCompatible{}
extension CGFloat:JQFisherCompatible{}
extension Float:JQFisherCompatible{}

public extension JQFisher where Base == Double{
    //小数位截取
    func truncate(places : Int)-> Double
    {
    return Double(Darwin.floor(pow(10.0, Double(places)) * self.base)/pow(10.0, Double(places)))
    }

    /// 角度转换：弧度转角度
    var degrees:Double{
        get{return self.base * (180.0 / .pi)}
    }

    /// 角度转换：角度转弧度
    var radians:Double{
        get{return self.base / 180.0 * .pi}
    }

    /// 四舍五入
    /// - Parameter places: 小数位 位数
    func roundTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self.base * divisor).rounded() / divisor
    }


    func mm()->String{return "\(self.base/1)mm"}
    func cm()-> String{return "\(self.base/10)cm"}
    func dm()->String{return "\(self.base/100)dm"}
    func m()->String{return "\(self.base/1000)m"}
    func km()->String{return "\(self.base/(1000*1000))km"}
    func unit()->String{
        if self.base > 0 && self.base < 1000{
            if String(format: "%.2lf", self.base).contains(".00"){
                return String(format: "%ld", Int(self.base))
            }else{
                return String(format: "%.2lf", self.base)
            }
        }else if self.base >= 1000 && self.base < 10000 {
            if String(format: "%.2lfK", self.base/1000.0).contains(".00") {
                return String(format: "%ldK", Int(self.base/1000.0))
            }else{
                return String(format: "%.2lfK", self.base/1000.0)
            }
        }else if self.base >= 10000{
            if String(format: "%.2lfW", self.base/10000.0).contains(".00") {
                return String(format: "%ldW", Int(self.base/10000.0))
            }else{
                return String(format: "%.2lfW", self.base/10000.0)
            }
        }else{
            return "0"
        }
    }

    /// 进行格式化
    var formatFloat:String{
        if fmodf(Float(self.base), 1) == 0 {
            return String(format: "%.0f", self.base)
        }else if fmodf(Float(self.base) * 10, 1) == 0{
            return String(format: "%.1f", self.base)
        }else{
            return String(format: "%.2f", self.base)
        }
    }

    @available(*,deprecated,message: "废弃")
    var ratioW:CGFloat{
        return CGFloat(self.base)
    }
}

public extension JQFisher where Base == CGFloat{
    /// 进行格式化
    var formatFloat:String{
        if fmodf(Float(self.base), 1) == 0 {
            return String(format: "%.0f", self.base)
        }else if fmodf(Float(self.base) * 10, 1) == 0{
            return String(format: "%.1f", self.base)
        }else{
            return String(format: "%.2f", self.base)
        }
    }

    //小数位截取
    func truncate(places : Int)-> Double
    {
    return Double(Darwin.floor(pow(10.0, Double(places)) * Double(self.base))/pow(10.0, Double(places)))
    }

    /// 角度转换：弧度转角度
    var degrees:CGFloat{
        get{return self.base * (180.0 / .pi)}
    }

    /// 角度转换：角度转弧度
    var radians:CGFloat{
        get{return self.base / 180.0 * .pi}
    }

    /// 截断
    /// - Parameter places: 截断小数位 位数
    func truncate(places: Int) -> CGFloat {
        let divisor = pow(10.0, CGFloat(places))
        return CGFloat(Int(self.base * divisor)) / CGFloat(divisor)
    }

    /// 四舍五入
    /// - Parameter places: 小数位 位数
    func roundTo(places: Int) -> CGFloat {
        let divisor = pow(10.0, CGFloat(places))
        return CGFloat((self.base * divisor).rounded() / divisor)
    }

    func mm()->String{return "\(self.base/1)mm"}
    func cm()-> String{return "\(self.base/10)cm"}
    func dm()->String{return "\(self.base/100)dm"}
    func m()->String{return "\(self.base/1000)m"}
    func km()->String{return "\(self.base/(1000*1000))km"}

    @available(*,deprecated,message: "废弃")
    var ratioW:CGFloat{
        return self.base
    }
}


