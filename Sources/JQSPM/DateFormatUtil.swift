//
//  MonthUtil.swift
//  YKTools
//
//  Created by 杨锴 on 2019/6/12.
//  Copyright © 2019 younger_times. All rights reserved.
//

import Foundation

private func GetBitInt(data:Int,length:Int,shift:Int)->Int{
    return (data & (((1 << length) - 1) << shift)) >> shift
}

private func SolarToInt(y:Int,m:Int,d:Int)->Int{
    let m = (m + 9) % 12;
    let y = y - m / 10;
    return 365 * y + y / 4 - y / 100 + y / 400 + (m * 306 + 5) / 10 + (d - 1)
}

private func SolarFromInt(g:Int)->Solar{
    var y = (10000 * g + 14780) / 3652425
    var ddd = g - (365 * y + y / 4 - y / 100 + y / 400)
    
    if (ddd < 0) {
        y+=1
        ddd = g - (365 * y + y / 4 - y / 100 + y / 400)
    }
    
    let mi = (100 * ddd + 52) / 3060
    let mm = (mi + 2) % 12 + 1
    y = y + (mi + 2) / 12;
    let dd = ddd - (mi * 306 + 5) / 10 + 1
    let solar = Solar()
    solar.solarYear = y
    solar.solarMonth = mm
    solar.solarDay = dd
    return solar
}

private func DoubleMonth(year:Int)->Int{
    return Date.solarTolunar[year-1900] & 0xf
}

// MARK: -- public
public func LunarToSolar(lunar:Lunar)->Solar{

    let days = Date.lunar_month_days[lunar.lunarYear - Date.lunar_month_days[0]]
    let leap = GetBitInt(data: days, length: 4, shift: 13)
    var offset = 0
    var loopend = leap
    
    if (!lunar.isleap) {
        if (lunar.lunarMonth <= leap || leap == 0) {
            loopend = lunar.lunarMonth - 1
        } else {
            loopend = lunar.lunarMonth
        }
    }
    
    var i = 0
    while i < loopend  {
        offset += GetBitInt(data: days, length: 1, shift: 12 - i) == 1 ? 30 : 29
        i+=1
    }
    
    offset += lunar.lunarDay
    
    let solar11 = Date.solar_1_1[lunar.lunarYear - Date.solar_1_1[0]]

    let y = GetBitInt(data: solar11, length: 12, shift: 9)
    let m = GetBitInt(data: solar11, length: 4, shift: 5)
    let d = GetBitInt(data: solar11, length: 5, shift: 0)
    
    let soloarInt = SolarToInt(y: y, m: m, d: d)
    return SolarFromInt(g: soloarInt + offset - 1)
}


/// 国历转农历
///
/// - Parameter solar: 国历
/// - Returns: 农历
public func SolarToLunar(solar:Solar)->Lunar{
    let lunar = Lunar()
    var index = solar.solarYear - Date.solar_1_1[0]
    let data = (solar.solarYear << 9) | (solar.solarMonth << 5) | (solar.solarDay)
    var solar11 = 0
    
    if (Date.solar_1_1[index] > data) {
        index-=1
    }
    
    solar11 = Date.solar_1_1[index];
    let y = GetBitInt(data: solar11, length: 12, shift: 9)
    let m = GetBitInt(data: solar11, length: 4, shift: 5)
    let d = GetBitInt(data: solar11, length: 5, shift: 0)
    var offset = SolarToInt(y: solar.solarYear, m: solar.solarMonth, d: solar.solarDay) - SolarToInt(y: y, m: m, d: d)
    
    let days = Date.lunar_month_days[index]
    let leap = GetBitInt(data: days, length: 4, shift: 13)
    
    let lunarY = index + Date.solar_1_1[0]
    var lunarM = 1
    var lunarD = 1
    offset += 1
    
    var i = 0
    while i < 13 {
        let dm = GetBitInt(data: days, length: 1, shift: 12 - i) == 1 ? 30 : 29
        
        if (offset > dm) {
            lunarM += 1
            offset -= dm
        } else {
            break
        }
        i+=1
    }
    
    lunarD = offset
    lunar.lunarYear = lunarY
    lunar.lunarMonth = lunarM
    lunar.isleap = false
    
    if (leap != 0 && lunarM > leap) {
        lunar.lunarMonth = lunarM - 1
        
        if (lunarM == leap + 1) {
            lunar.isleap = true
        }
    }
    
    lunar.lunarDay = lunarD
    return lunar
}

/// 农历月天数
///
/// - Parameters:
///   - year: 农历年
///   - month: 农历月
///   - leapMonth: 是否是闰月
/// - Returns: 返回天数
public func LunarMonthDays(year:Int,month:Int,leapMonth:Bool)->Int{
    
    if leapMonth{
        let days = DoubleMonth(year: year)
        if days != 0 {
            return (((Date.solarTolunar[year - 1900] & 0x10000) != 0) ? 30 : 29)
        }
    }
    return (((Date.solarTolunar[year - 1900] & (0x10000 >> month)) != 0) ? 30 : 29)
}


/// 计算国历月天数
///
/// - Parameters:
///   - year: 国历年
///   - month: 国历月
/// - Returns: 天数
public func SolarMonthDays(year:Int,month:Int)->Int{

    switch month {
    case 1,3,5,7,8,10,12:
        return 31
    case 4,6,9,11:
        return 30
    case 2:
        if leapYear(year: year){return 29}
        return 28
    default:
        return 0
    }
}

/// 闰年判断
///
/// - Parameter year: 年份
/// - Returns: 结果
public func leapYear(year:Int)->Bool{
    if year % 400 == 0{
        return true
    }
    else if year % 4 == 0 && year % 100 != 0{
        return true
    }else{
        return false
    }
}

public func lunarMonthMap(_ month:String)->Int{
    
    switch month {
    case "正月","闰正月","一月","闰一月":
        return 1
    case "二月", "闰二月":
        return 2
    case "三月", "闰三月":
        return 3
    case "四月", "闰四月":
        return 4
    case "五月", "闰五月":
        return 5
    case "六月", "闰六月":
        return 6
    case "七月", "闰七月":
        return 7
    case "八月", "闰八月":
        return 8
    case "九月", "闰九月":
        return 9
    case "十月", "闰十月":
        return 10
    case "十一月", "闰十一月","冬月","闰冬月":
        return 11
    case "腊月", "闰腊月","十二月","闰十二月":
        return 12
    default: break
    }
    return 0
}

public func formatlunar(year:Int,month:Int, day:Int)->String{
    return String(format: "%d年%@%@", year,Date.chineseMonths[month-1],Date.chineseDays[day-1])
}
