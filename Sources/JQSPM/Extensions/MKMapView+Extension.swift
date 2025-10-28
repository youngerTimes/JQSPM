//
//  File 2.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/1/6.
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import MapKit

extension MKMapView:JQFisherCompatible{}

extension JQFisher where Base == MKMapView{
    // 缩放级别
    @MainActor var zoomLevel: Int {
        // 获取缩放级别
        get {
            return Int(log2(360 * (Double(self.base.frame.size.width / 256) / self.base.region.span.longitudeDelta)) + 1)
        }
        // 设置缩放级别
        set(newZoomLevel) {
            setCenterCoordinate(coordinate: self.base.centerCoordinate, zoomLevel: newZoomLevel, animated: false)
        }
    }
}
extension JQFisher where Base == MKMapView{


    ///获取当前屏幕半径
    @MainActor func getRadius()->Double{
        let centerCoor = self.base.centerCoordinate
        let centerLocation = CLLocation(latitude: centerCoor.latitude, longitude: centerCoor.longitude)

        let topCenterCoor = self.base.convert(CGPoint(x: 0, y: self.base.frame.height / 2), toCoordinateFrom: self.base)
        let topCenterLocation = CLLocation(latitude: topCenterCoor.latitude, longitude: topCenterCoor.longitude)

        return centerLocation.distance(from: topCenterLocation)
    }

    @MainActor func getCurrentMapTiles(for mapView: MKMapView, tileServerURL: String) -> [String] {
        var tiles = [String]()

        let zoomLevel = self.zoomLevel
        let region = mapView.region

        let numTiles = pow(2.0, Double(zoomLevel))
        let longitudePerTile = 360.0 / numTiles

        let longitudeOffset = region.center.longitude + 180
        let longitudeStart = Int((longitudeOffset - region.span.longitudeDelta / 2.0) / longitudePerTile)
        let longitudeEnd = Int((longitudeOffset + region.span.longitudeDelta / 2.0) / longitudePerTile)

        for lon in longitudeStart...longitudeEnd {
            let minLat = region.center.latitude - region.span.latitudeDelta / 2.0
            let maxLat = region.center.latitude + region.span.latitudeDelta / 2.0

            let minY = Int((1.0 - log(tan(minLat * Double.pi / 180.0) + 1.0 / cos(minLat * Double.pi / 180.0)) / Double.pi) / 2.0 * numTiles)
            let maxY = Int((1.0 - log(tan(maxLat * Double.pi / 180.0) + 1.0 / cos(maxLat * Double.pi / 180.0)) / Double.pi) / 2.0 * numTiles)

            // 检查minY和maxY的顺序
            let startY = min(minY, maxY)
            let endY = max(minY, maxY)

            for y in startY...endY {
                let x = lon
                let tileURL = String(format: "%@/%d/%d/%d.png", tileServerURL, zoomLevel, x, y)
                tiles.append(tileURL)
            }
        }

        return tiles
    }

    //显示多个点位在地图上
    @MainActor func setVisibleMapRect(_ coordinates:[CLLocationCoordinate2D],edgePadding:UIEdgeInsets = .zero,animated:Bool = true){
        let rect =  JQFisher<MKMapView>.getMapRect(for: coordinates)
        self.base.setVisibleMapRect(rect, edgePadding: edgePadding, animated: animated)
    }

}

extension JQFisher where Base == MKMapView{
    // 设置缩放级别时调用
    @MainActor private func setCenterCoordinate(coordinate: CLLocationCoordinate2D, zoomLevel: Int, animated: Bool) {
        let span = MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 360 / pow(2, Double(zoomLevel)) * Double(self.base.frame.size.width) / 256)
        self.base.setRegion(MKCoordinateRegion(center: coordinate, span: span), animated: animated)
    }
}

extension JQFisher where Base == MKMapView{
    /// 根据多个坐标点计算并返回合适的 MKMapRect 参数
    /// - Parameter coordinates: 坐标点数组
    /// - Returns: 包含 mapRect 和 region 的元组
    static func calculateMapRect(for coordinates: [CLLocationCoordinate2D]) -> (mapRect: MKMapRect, region: MKCoordinateRegion) {
        guard !coordinates.isEmpty else {
            // 如果没有坐标点，返回默认的北京区域
            let defaultCoordinate = CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
            let defaultRegion = MKCoordinateRegion(center: defaultCoordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
            return (MKMapRect.null, defaultRegion)
        }

        // 如果只有一个点，返回以该点为中心的区域
        if coordinates.count == 1 {
            let coordinate = coordinates[0]
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            return (MKMapRect.null, region)
        }

        // 计算边界
        let minLat = coordinates.map { $0.latitude }.min()!
        let maxLat = coordinates.map { $0.latitude }.max()!
        let minLon = coordinates.map { $0.longitude }.min()!
        let maxLon = coordinates.map { $0.longitude }.max()!

        // 计算中心点
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)

        // 计算跨度并添加边距
        let latSpan = maxLat - minLat
        let lonSpan = maxLon - minLon

        // 添加 20% 的边距
        let paddingFactor: Double = 0.2
        let paddedLatSpan = latSpan * (1 + paddingFactor)
        let paddedLonSpan = lonSpan * (1 + paddingFactor)

        // 确保最小跨度（避免点太近时地图显示过小）
        let minSpan: Double = 0.001 // 约100米
        let finalLatSpan = max(paddedLatSpan, minSpan)
        let finalLonSpan = max(paddedLonSpan, minSpan)

        // 创建 MKCoordinateRegion
        let span = MKCoordinateSpan(latitudeDelta: finalLatSpan, longitudeDelta: finalLonSpan)
        let region = MKCoordinateRegion(center: center, span: span)

        // 创建 MKMapRect
        let topLeft = CLLocationCoordinate2D(latitude: centerLat + finalLatSpan/2, longitude: centerLon - finalLonSpan/2)
        let bottomRight = CLLocationCoordinate2D(latitude: centerLat - finalLatSpan/2, longitude: centerLon + finalLonSpan/2)

        let topLeftPoint = MKMapPoint(topLeft)
        let bottomRightPoint = MKMapPoint(bottomRight)

        let mapRect = MKMapRect(
            x: min(topLeftPoint.x, bottomRightPoint.x),
            y: min(topLeftPoint.y, bottomRightPoint.y),
            width: abs(bottomRightPoint.x - topLeftPoint.x),
            height: abs(bottomRightPoint.y - topLeftPoint.y)
        )

        return (mapRect, region)
    }

    /// 简化版本：只返回 MKMapRect
    /// - Parameter coordinates: 坐标点数组
    /// - Returns: MKMapRect
    static func getMapRect(for coordinates: [CLLocationCoordinate2D]) -> MKMapRect {
        let result = calculateMapRect(for: coordinates)
        return result.mapRect
    }

    /// 简化版本：只返回 MKCoordinateRegion
    /// - Parameter coordinates: 坐标点数组
    /// - Returns: MKCoordinateRegion
    static func getRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        let result = calculateMapRect(for: coordinates)
        return result.region
    }
}
