//
//  LaunchImageHelper.swift
//  XQMuse
//
//  Created by 无故事王国 on 2024/11/5.
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if canImport(UIKit)

/// 自定义创建启动图：下次运行时生效
@MainActor final class LaunchImageHelper {
     static func snapshotStoryboard(sbName: String, isPortrait: Bool) -> UIImage? {
        if sbName.isEmpty {
            return nil
        }

        let storyboard = UIStoryboard(name: sbName, bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() else {
            return nil
        }

        vc.view.frame = UIScreen.main.bounds
        if isPortrait {
            if vc.view.frame.size.width > vc.view.frame.size.height {
                vc.view.frame = CGRect(x: 0, y: 0, width: vc.view.frame.size.height, height: vc.view.frame.size.width)
            }
        } else {
            if vc.view.frame.size.width < vc.view.frame.size.height {
                vc.view.frame = CGRect(x: 0, y: 0, width: vc.view.frame.size.height, height: vc.view.frame.size.width)
            }
        }

        vc.view.setNeedsLayout()
        vc.view.layoutIfNeeded()

        UIGraphicsBeginImageContextWithOptions(vc.view.frame.size, false, UIScreen.main.scale)
        vc.view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    static func snapshotStoryboardForPortrait(sbName: String) -> UIImage? {
        return snapshotStoryboard(sbName: sbName, isPortrait: true)
    }

    static func snapshotStoryboardForLandscape(sbName: String) -> UIImage? {
        return snapshotStoryboard(sbName: sbName, isPortrait: false)
    }

    static func changeAllLaunchImageToPortrait(_ image: UIImage?) {
        guard let image = image else {
            return
        }
        // 全部替换为竖屏启动图
        let resizedImage = resizeImage(image, toPortraitScreenSize: true)
        BBADynamicLaunchImage.replaceLaunchImage(resizedImage)
    }

    static func changeAllLaunchImageToLandscape(_ image: UIImage?) {
        guard let image = image else {
            return
        }
        // 全部替换为横屏启动图
        let resizedImage = resizeImage(image, toPortraitScreenSize: false)
        BBADynamicLaunchImage.replaceLaunchImage(resizedImage)
    }

    static func changePortraitLaunchImage(_ p: UIImage) {
        // Implementation for this function is missing
    }

    static func resizeImage(_ image: UIImage, toPortraitScreenSize: Bool) -> UIImage {
        // Implementation for this function is missing
        return image
    }
}


@MainActor private class BBADynamicLaunchImage {
    static func launchImageCacheDirectory() -> String? {
        let bundleID = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String
        let fm = FileManager.default

        // iOS13之前
        if var cachesDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
            cachesDirectory.append(contentsOf: "Snapshots")
            cachesDirectory.append(contentsOf: bundleID!)
            if fm.fileExists(atPath: cachesDirectory) {
                return cachesDirectory
            }
        }

        // iOS13
        if let libraryDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first {
            let snapshotsPath = String(format: "%@/SplashBoard/Snapshots/%@ - {DEFAULT GROUP}", libraryDirectory, bundleID ?? "")
            if fm.fileExists(atPath: snapshotsPath) {
                return snapshotsPath
            }
        }

        return nil
    }

    static func isSnapShotName(_ name: String) -> Bool {
        // 新系统后缀
        let snapshotSuffixs = ".ktx"
        if name.hasSuffix(snapshotSuffixs) {
            return true
        }

        // 老系统后缀
        let snapshotSuffixs2 = ".png"
        if name.hasSuffix(snapshotSuffixs2) {
            return true
        }

        return false
    }

    @discardableResult
    static func replaceLaunchImage(_ replacementImage: UIImage?) -> Bool {
        guard let image = replacementImage else {return false}
        return self.replaceLaunchImage(replacementImage: image, compressionQuality: 1.0, customValidation: nil)
    }

    @discardableResult
    static func replaceLaunchImage(_ replacementImage: UIImage?, compressionQuality: CGFloat) -> Bool {
        guard let image = replacementImage else {return false}
        return self.replaceLaunchImage(replacementImage: image, compressionQuality: compressionQuality, customValidation: nil)
    }

    static func replaceLaunchImage(replacementImage: UIImage, compressionQuality: CGFloat, customValidation: ((UIImage,UIImage) -> Bool)?) -> Bool {

        let data = replacementImage.jpegData(compressionQuality: compressionQuality)
        if data == nil {
            return false
        }

        if !checkImageMatchScreenSize(image: replacementImage) {
            return false
        }

        guard let cacheDir = launchImageCacheDirectory() else {
            return false
        }

        let cachesParentDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        let tmpDir = (cachesParentDir as NSString).appendingPathComponent("_tmpLaunchImageCaches")

        let fm = FileManager.default
        if fm.fileExists(atPath: tmpDir) {
            do {
                try fm.removeItem(atPath: tmpDir)
            } catch {
                return false
            }
        }

        do {
            try fm.moveItem(atPath: cacheDir, toPath: tmpDir)
        } catch {
            return false
        }

        var cacheImageNames = [String]()
        if let contents = try? fm.contentsOfDirectory(atPath: tmpDir) {
            for name in contents {
                if isSnapShotName(name) {
                    cacheImageNames.append(name)
                }
            }
        }

        for name in cacheImageNames {
            let filePath = (tmpDir as NSString).appendingPathComponent(name)
            var result = true

            if customValidation != nil{
                if let cachedImageData = try? Data(contentsOf: URL(string: filePath)!),let cachedImage = imageFromData(data: cachedImageData as NSData){
                    result = customValidation!(cachedImage,replacementImage)
                }
            }

            if result {
                do {
                    try data?.write(to: URL(fileURLWithPath: filePath), options: .atomic)
                } catch {
                    return false
                }
            }
        }


        try? fm.moveItem(atPath: tmpDir, toPath: cacheDir)
        if fm.fileExists(atPath: tmpDir) {
            do {
                try fm.removeItem(atPath: tmpDir)
            } catch {
                return false
            }
        }

        return true
    }



    static func imageFromData(data: NSData) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data, nil) else {
            return nil
        }

        if let imageRef = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            let originImage = UIImage(cgImage: imageRef)
            return originImage
        }

        return nil
    }

    func getImageSize(imageData: NSData) -> CGSize {
        guard let source = CGImageSourceCreateWithData(imageData, nil) else {
            return CGSize.zero
        }

        if let imageRef = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            let width = CGFloat(imageRef.width)
            let height = CGFloat(imageRef.height)
            return CGSize(width: width, height: height)
        }

        return CGSize.zero
    }


    /// 检查图片大小
    static func checkImageMatchScreenSize(image: UIImage) -> Bool {
        let screenSize = CGSize(width: UIScreen.main.bounds.size.width * UIScreen.main.scale,
                                height: UIScreen.main.bounds.size.height * UIScreen.main.scale)
        let imageSize = CGSize(width: image.size.width * image.scale,
                               height: image.size.height * image.scale)

        if imageSize.equalTo(screenSize) {
            return true
        }

        if imageSize.equalTo(CGSize(width: screenSize.height, height: screenSize.width)) {
            return true
        }
        
        return false
    }
}
#endif
