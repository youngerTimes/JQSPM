//
//  PHAsset+JQExtension.swift
//  JQTools
//
//  Created by 无故事王国 on 2023/7/24.
//

import Photos
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if canImport(UIKit)
public extension PHAsset{

    @MainActor func toImage()->UIImage{
        var image = UIImage()

         // 新建一个默认类型的图像管理器imageManager
         let imageManager = PHImageManager.default()

         // 新建一个PHImageRequestOptions对象
         let imageRequestOption = PHImageRequestOptions()

         // PHImageRequestOptions是否有效
         imageRequestOption.isSynchronous = true

         // 缩略图的压缩模式设置为无
         imageRequestOption.resizeMode = .none

         // 缩略图的质量为高质量，不管加载时间花多少
         imageRequestOption.deliveryMode = .highQualityFormat

         // 按照PHImageRequestOptions指定的规则取出图片
        let size = CGSize(width: Double(pixelWidth) * UIScreen.main.scale, height: Double(pixelHeight) * UIScreen.main.scale)
        imageManager.requestImage(for: self, targetSize: size, contentMode: .aspectFill, options: imageRequestOption, resultHandler: {
             (result, _) -> Void in
             image = result!
         })
         return image
    }

    /// 保存图片，视频至相册
    /// - Parameter imagePath: 图片地址
    func saveToAlbum(filePath:String,type:PHAssetMediaType) async -> Bool{
        guard type == .image || type == .video else {return false}
        let uRL = URL(fileURLWithPath: filePath)
        return await withCheckedContinuation { block in
            PHPhotoLibrary.shared().performChanges {
                if type == .video{
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: uRL)
                }else if type == .image{
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: uRL)
                }
            } completionHandler: {  (success, error) in
                block.resume(returning: success)
            }
        }
    }
}

extension PHAssetResource {
    func originFileUrl() -> URL? {
        return self.value(forKey: "_privateFileURL") as? URL
    }
}

extension PHAsset {
    var currentResource: PHAssetResource? {
        let resourceTypes = supportMediaTypes
        let resources = PHAssetResource.assetResources(for: self)
        for assetRes in resources {
            if resourceTypes.contains(assetRes.type) {
                return assetRes
            }
        }
        return .none
    }

    func currentFileUrl() -> URL? {
        return currentResource?.originFileUrl()
    }
}

fileprivate extension PHAsset {
    var supportMediaTypes: [PHAssetResourceType] {
        switch mediaType {
        case .image:
            return [.photo]
        case .video:
            return [.pairedVideo, .video]
        default:
            return []
        }
    }

    var uploadFileName: String {
        if let name = PHAssetResource.assetResources(for: self).first?.originalFilename, name.count > 0 {
            return name
        }
        return mediaType == .video ? "video_file.mov" : "image_file.jpg"
    }

    var mimeType: String {
        return mediaType == .video ? "video/mp4" : "image/png"
    }
}

extension PHAsset  {
    var data: Data? {
        guard let resource = currentResource, let originUrl = resource.originFileUrl(), let sizeOnDisk: UInt64 = resource.value(forKey: "fileSize") as? UInt64, sizeOnDisk > 0 else {
            return .none
        }
        let fileName = self.uploadFileName
        _ = self.mimeType
        let destationPath = tempSavePath(originFlieName: fileName)
        try? FileManager.default.removeItem(at: destationPath)
        try? FileManager.default.copyItem(at: originUrl, to: destationPath)
        if FileManager.default.fileExists(atPath: destationPath.path) {
            //            let formData = MultipartFormData(provider: .data((try? Data(contentsOf: destationPath)) ?? Data()), name: "file", fileName: fileName, mimeType: mimeType)
            ////            let formData = MultipartFormData(provider: .data((try? Data(contentsOf: destationPath, options: .mappedIfSafe)) ?? Data()), name: "imgOrVideo", fileName: "", mimeType: (self.mediaType == .video ? "mov/mp4" : "image/png"))
            return try? Data(contentsOf: destationPath)
        }
        return .none
    }

    func tempSavePath(originFlieName: String) -> URL {
        var tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        tempURL.appendPathComponent(originFlieName)
        return tempURL
    }


    func geyAssetSize() -> String {
        let resources = PHAssetResource.assetResources(for: self) // your PHAsset
        var sizeOnDisk: Int64? = 0
        if let resource = resources.first {
            let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong
            sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64!))
            if let size = sizeOnDisk {
                let formatter: ByteCountFormatter = ByteCountFormatter()
                formatter.countStyle = .binary
                formatter.allowedUnits = .useMB
                let str = formatter.string(fromByteCount: Int64(size))
                return str
            }
        }
        return ""
    }

}

extension Array where Element == PHAsset {
    func convertToFiles(finish handle: @escaping ([URL]) -> Void) {
        var urls: [URL] = []
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: self.count)
        for asset in self {
            semaphore.wait()
            let path = asset.tempSavePath(originFlieName: asset.uploadFileName)
            asset.saveToFilePath(to: path) {
                if FileManager.default.fileExists(atPath: path.path) {
                    urls.append(path)
                }
                semaphore.signal()
            }
        }
        handle(urls)
    }
}




extension PHAsset {
    @MainActor func generatorThumb(finish: @escaping (UIImage?) -> Void) {
        PHImageManager.default().requestImage(for: self, targetSize: CGSize(width: (JQ_ScreenWidth / 3.0) * UIScreen.main.scale, height: (JQ_ScreenWidth / 3.0) * UIScreen.main.scale), contentMode: .aspectFill, options: .none) { image, _ in
            finish(image)
        }
    }

    func asyncGetData(finish: @escaping (Data?) -> Void) {
        PHImageManager.default().requestImageData(for: self, options: .none) { data, _, _, _ in
            finish(data)
        }
    }

    func saveToFilePath(to path: URL, finish: @escaping () -> Void) {
        switch mediaType {
        case .image:
            saveImage(to: path, finish: finish)
        case .video:
            saveVideo(to: path, finish: finish)
        default:
            finish()
        }
        //        guard let resource =  self.currentResource, let resultPath = resource.value(forKey: "") {
        //            finish()
        //            return
        //        }
        //        finish()
    }

    private func saveImage(to path: URL, finish: @escaping () -> Void) {
        PHImageManager.default().requestImageData(for: self, options: .none) { data, _, _, _ in
            defer {
                finish()
            }
            do {
                try data?.write(to: path)
            } catch let e {
                print("save error : \(e)")
            }
        }
    }

    private func saveVideo(to path: URL, finish: @escaping () -> Void) {
        PHImageManager.default().requestAVAsset(forVideo: self, options: .none) { _, _, info in
            let sandboxExtensionTokenKey = info!["PHImageFileSandboxExtensionTokenKey"] as! String
            _ = sandboxExtensionTokenKey.split(separator: ";")
            finish()
        }
    }

    var isImage: Bool {
        switch mediaType {
        case .image:
            return true
        case .unknown:
            return false
        case .video:
            return false
        case .audio:
            return false
        @unknown default:
            return false
        }
    }

}

#endif
