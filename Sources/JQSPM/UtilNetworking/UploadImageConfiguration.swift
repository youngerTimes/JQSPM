//
//  UploadImageConfiguration.swift
//  UtilNetworking
//
//  Created by baipayne on 2025/3/25.
//

import Foundation

// Use for upload image with multipart/form-data
public protocol UploadImageConfiguration {
    var boundary: String { get }
    func makeUploadImageHeader(_ imageDatas: [Data]) -> [String: String]
    func makeUploadImageBody(_ imageDatas: [Data], names: [String]) -> Data?
    func makePart(_ imageData: Data, name: String, fileName: String) -> Data
}

public extension UploadImageConfiguration {
    var boundary: String {
        "-----------------UploadImageBoundary"
    }

    func makeUploadImageHeader(_ imageDatas: [Data]) -> [String: String] {
        guard !imageDatas.isEmpty else {
            return [:]
        }

        let contentLength = imageDatas.reduce(0) { $0 + $1.count }
        return [
            "Content-Type": "multipart/form-data; boundary=\(boundary)",
            "Content-Length": "\(contentLength)"
        ]
    }

    func makeUploadImageBody(_ imageDatas: [Data], names: [String]) -> Data? {
        guard !imageDatas.isEmpty,
              !names.isEmpty,
              imageDatas.count == names.count else {
            NetworkClientLogger.logger.warning("Convert upload image body fail")
            return nil
        }

        let imageDataInfo = zip(imageDatas, names)
        var bodyData = Data()
        imageDataInfo.forEach { data, name in
            bodyData.append(makePart(data, name: name, fileName: name))
        }
        return bodyData
    }

    func makePart(_ imageData: Data, name: String, fileName: String) -> Data {
        guard !imageData.isEmpty,
              let startBoundaryData = String(format: "\r\n--%@\r\n", boundary).data(using: .utf8),
              let contentDispositionData = String(format: "Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", name, fileName).data(using: .utf8),
              let contentTypeData = "Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8),
              let endBoundaryData = String(format: "\r\n--%@--\r\n", boundary).data(using: .utf8) else {
            NetworkClientLogger.logger.warning("Convert image part body fail")
            return Data()
        }

        var partData = Data()
        partData.append(startBoundaryData)
        partData.append(contentDispositionData)
        partData.append(contentTypeData)
        partData.append(imageData)
        partData.append(endBoundaryData)
        return partData
    }
}
