//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/6/12.
//

import Foundation
import MapKit

public extension CLLocationCoordinate2D{

    /// 计算两点的角度
    /// 需要注意的时，如果对地图点位旋转角度是需要角度转弧度
    /// let radians = CGFloat(angle * .pi / 180)
    ///     vehicleAnnotationView?.transform = CGAffineTransform(rotationAngle: radians)
    /// - Parameters:
    ///   - pointA: 点位1
    ///   - pointB: 点位2
    /// - Returns: 返回两点形成的夹角
    static func CalculatingAngle(from pointA: CLLocationCoordinate2D, to pointB: CLLocationCoordinate2D) -> Double? {
        // 转换为弧度
        let latA = pointA.latitude.jq.radians
        let lonA = pointA.longitude.jq.radians
        let latB = pointB.latitude.jq.radians
        let lonB = pointB.longitude.jq.radians

        // 计算经度差
        let deltaLon = lonB - lonA

        // 核心公式（基于球面三角学）
        let y = sin(deltaLon) * cos(latB)
        let x = cos(latA) * sin(latB) - sin(latA) * cos(latB) * cos(deltaLon)
        let bearingRadians = atan2(y, x)

        // 转换为角度（0°~360°）
        let bearingDegrees = bearingRadians.jq.degrees
        let normalizedBearing = (bearingDegrees + 360).truncatingRemainder(dividingBy: 360)

        return normalizedBearing
    }
}

