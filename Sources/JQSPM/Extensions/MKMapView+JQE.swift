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

    // 设置缩放级别时调用
    @MainActor private func setCenterCoordinate(coordinate: CLLocationCoordinate2D, zoomLevel: Int, animated: Bool) {
        let span = MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 360 / pow(2, Double(zoomLevel)) * Double(self.base.frame.size.width) / 256)
        self.base.setRegion(MKCoordinateRegion(center: coordinate, span: span), animated: animated)
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
}
