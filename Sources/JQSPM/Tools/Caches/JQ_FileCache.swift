//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/12/2.
//

import Foundation


/// 文件缓存
/**
 ```swift
 // 使用示例：缓存文章列表
 struct Article: Codable {
 let id: Int
 let title: String
 let content: String
 let publishDate: Date
 }

 let fileCache = FileCache()

 func cacheArticlesExample() {
 let articles = [
 Article(id: 1, title: "Swift 编程", content: "Swift 基础知识...", publishDate: Date()),
 Article(id: 2, title: "SwiftUI 教程", content: "SwiftUI 入门...", publishDate: Date())
 ]

 // 保存文章列表
 fileCache.save(articles, toFile: "articles")

 // 加载文章列表
 if let cachedArticles = fileCache.load([Article].self, fromFile: "articles") {
 print("从缓存加载 \(cachedArticles.count) 篇文章")
 }
 }
 ```
 */
public class JQ_FileCache {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init() {
        let documentsPath = fileManager.urls(for: .documentDirectory,
                                             in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("Cache")

        createCacheDirectoryIfNeeded()
    }

    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory,
                                             withIntermediateDirectories: true)
        }
    }

    public func save<T: Codable>(_ object: T, toFile fileName: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(fileName).json")

        do {
            let data = try encoder.encode(object)
            try data.write(to: fileURL)
            print("数据已保存到: \(fileURL.path)")
        } catch {
            print("保存文件失败: \(error)")
        }
    }

    public func load<T: Codable>(_ type: T.Type, fromFile fileName: String) -> T? {
        let fileURL = cacheDirectory.appendingPathComponent("\(fileName).json")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(type, from: data)
        } catch {
            print("加载文件失败: \(error)")
            return nil
        }
    }

    public func delete(fileName: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(fileName).json")
        try? fileManager.removeItem(at: fileURL)
    }

    public func exists(fileName: String) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent("\(fileName).json")
        return fileManager.fileExists(atPath: fileURL.path)
    }

    public func clearAll() {
        try? fileManager.removeItem(at: cacheDirectory)
        createCacheDirectoryIfNeeded()
    }
}
