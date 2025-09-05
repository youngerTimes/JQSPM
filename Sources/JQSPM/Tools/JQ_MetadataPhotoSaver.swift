//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/9/4.
//

import Foundation
#if canImport(UIKit)
import UIKit
import Photos
import CoreLocation
import ImageIO

class JQ_MetadataPhotoSaver: NSObject {
    /// 保存图片及原始元数据到相册
    /// - Parameters:
    ///   - image: 从UIImagePickerController获取的图片
    ///   - metadata: 从info[.mediaMetadata]获取的元数据
    ///   - completion: 完成回调
    func savePhotoWithOriginalMetadata(image: UIImage,
                                       metadata: [String: Any]?,
                                       completion: @escaping @Sendable (Bool, Error?) -> Void) {
        // 检查相册权限
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard let self = self else {
                return
            }
            //
            // 将图片和元数据合并为带元数据的图片数据
            guard let imageData = self.combineImageAndMetadata(image: image, metadata: metadata) else {
                completion(false, NSError(domain: "MetadataSaver",
                                          code: -2,
                                          userInfo: [NSLocalizedDescriptionKey: "无法处理图片数据"]))
                return
            }

            // 保存到相册
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                // 添加图片资源，使用包含元数据的imageData
                creationRequest.addResource(with: .photo, data: imageData, options: nil)

                // 如果有位置信息，单独设置（元数据中的位置可能不被直接识别）
                if let location = metadata?["{GPS}"] as? [String: Any] {
                    creationRequest.location = self.locationFromGPSMetadata(location)
                }

                // 设置创建日期（使用元数据中的拍摄时间）
                if let date = self.captureDateFromMetadata(metadata) {
                    creationRequest.creationDate = date
                }

            }, completionHandler: { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            })
        }
    }

    /// 将图片和元数据合并为带元数据的图片数据
    private func combineImageAndMetadata(image: UIImage, metadata: [String: Any]?) -> Data? {
        guard let cgImage = image.cgImage else { return nil }

        // 创建图片数据写入器
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            "public.heic" as CFString,
            1, nil
        ) else { return nil }

        // 合并元数据
        let outputMetadata = metadata ?? [:]
        //
        //        // 添加方向信息（确保图片方向正确）
        //        outputMetadata[kCGImagePropertyOrientation as String] = image.imageOrientation.rawValue


        // 将图片和元数据添加到写入器
        CGImageDestinationAddImage(destination, cgImage, outputMetadata as CFDictionary)

        // 完成写入
        if CGImageDestinationFinalize(destination) {
            return mutableData as Data
        }
        return nil
    }

    /// 从元数据中解析拍摄日期
    private func captureDateFromMetadata(_ metadata: [String: Any]?) -> Date? {
        guard let exif = metadata?["{Exif}"] as? [String: Any],
              let dateString = exif["DateTimeOriginal"] as? String else {
            return nil
        }

        // EXIF日期格式通常为 "yyyy:MM:dd HH:mm:ss"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: dateString)
    }

    /// 从GPS元数据解析位置信息
    private func locationFromGPSMetadata(_ gpsMetadata: [String: Any]) -> CLLocation? {
        // 解析纬度
        guard let latitude = gpsMetadata["Latitude"] as? Double,
              let latitudeRef = gpsMetadata["LatitudeRef"] as? String else {
            return nil
        }

        // 解析经度
        guard let longitude = gpsMetadata["Longitude"] as? Double,
              let longitudeRef = gpsMetadata["LongitudeRef"] as? String else {
            return nil
        }

        // 根据方向调整正负（南纬和西经为负值）
        let adjustedLatitude = latitudeRef == "S" ? -latitude : latitude
        let adjustedLongitude = longitudeRef == "W" ? -longitude : longitude

        return CLLocation(
            latitude: adjustedLatitude,
            longitude: adjustedLongitude
        )
    }
}
#endif

