//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/12/2.
//

import Foundation
#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif



/// 图片缓存
/**
```swift
 // 使用示例：缓存网络图片
 func cacheImageExample() async {
 let imageURL = "https://example.com/image.jpg"
 let cacheKey = imageURL.hashValue.description

 // 检查缓存
 if let cachedImage = ImageCache.shared.image(forKey: cacheKey) {
 print("从缓存加载图片")
 // 使用缓存的图片
 return
 }

 // 下载并缓存图片
 do {
 let (data, _) = try await URLSession.shared.data(from: URL(string: imageURL)!)

 #if canImport(UIKit)
 if let image = UIImage(data: data) {
 ImageCache.shared.setImage(image, forKey: cacheKey)
 print("图片已下载并缓存")
 }
 #elseif canImport(AppKit)
 if let image = NSImage(data: data) {
 ImageCache.shared.setImage(image, forKey: cacheKey)
 print("图片已下载并缓存")
 }
 #endif
 } catch {
 print("下载图片失败: \(error)")
 }
 }
```
 */
public class JQ_ImageCache {
    @MainActor static let shared = JQ_ImageCache()

    private let memoryCache = NSCache<NSString, PlatformImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        let cachesPath = fileManager.urls(for: .cachesDirectory,
                                          in: .userDomainMask).first!
        cacheDirectory = cachesPath.appendingPathComponent("Images")

        // 配置内存缓存
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB

        createCacheDirectoryIfNeeded()
    }

    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory,
                                             withIntermediateDirectories: true)
        }
    }

    func setImage(_ image: PlatformImage, forKey key: String) {
        // 存储到内存缓存
#if canImport(UIKit)
        let cost = Int(image.size.width * image.size.height)
#elseif canImport(AppKit)
        let cost = Int(image.size.width * image.size.height)
#endif
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)

        // 存储到磁盘缓存
        DispatchQueue.global(qos: .background).async {
            if let data = self.imageToData(image) {
                let fileURL = self.cacheDirectory.appendingPathComponent(key)
                try? data.write(to: fileURL)
            }
        }
    }

    func image(forKey key: String) -> PlatformImage? {
        // 首先检查内存缓存
        if let image = memoryCache.object(forKey: key as NSString) {
            return image
        }

        // 然后检查磁盘缓存
        let fileURL = cacheDirectory.appendingPathComponent(key)
        if let image = dataToImage(from: fileURL) {
            // 重新加载到内存缓存
            memoryCache.setObject(image, forKey: key as NSString)
            return image
        }

        return nil
    }

    func removeImage(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)

        let fileURL = cacheDirectory.appendingPathComponent(key)
        try? fileManager.removeItem(at: fileURL)
    }

    func clearAll() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        createCacheDirectoryIfNeeded()
    }

    // MARK: - Platform-specific helpers

    private func imageToData(_ image: PlatformImage) -> Data? {
#if canImport(UIKit)
        return image.jpegData(compressionQuality: 0.8)
#elseif canImport(AppKit)
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
#endif
    }

    private func dataToImage(from url: URL) -> PlatformImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }

#if canImport(UIKit)
        return UIImage(data: data)
#elseif canImport(AppKit)
        return NSImage(data: data)
#endif
    }
}
