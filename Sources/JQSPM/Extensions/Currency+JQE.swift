//
//  Currency+Extension.swift
//  Salary
//
//  Created by 无故事王国 on 2020/9/7.
//  Copyright © 2020 Mr. Hu. All rights reserved.
//

import Foundation

//货币相关的扩展
extension JQFisher where Base == Double{
    public func fuCoin(_ style:NumberFormatter.Style = .decimal,format:String = ",###.##")->String{
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        formatter.positiveFormat = format
        return formatter.string(from: NSNumber(value: self.base)) ?? ""
    }
}

extension JQFisher where Base == Float{
    public func fuCoin(_ style:NumberFormatter.Style = .decimal,format:String = ",###.##")->String{
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        formatter.positiveFormat = format
        return formatter.string(from: NSNumber(value: self.base)) ?? ""
    }
}



extension JQFisher where Base == Int{
    public func fuCoin(_ style:NumberFormatter.Style = .decimal,format:String = ",###.##")->String{
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        formatter.positiveFormat = format
        return formatter.string(from: NSNumber(value: self.base)) ?? ""
    }
}
