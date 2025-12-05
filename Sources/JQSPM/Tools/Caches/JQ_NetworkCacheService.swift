//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/12/2.
//

import Foundation


/// 网络缓存
/**
 ```swift
 // 使用示例：网络请求缓存
 let networkCache = NetworkCacheService()

 func networkCacheExample() async {
 let url = URL(string: "https://api.example.com/users")!

 do {
 // 首次请求（从网络获取）
 let users: [User] = try await networkCache.fetchData([User].self, from: url)
 print("首次加载: \(users.count) 个用户")

 // 再次请求（可能从缓存获取）
 let cachedUsers: [User] = try await networkCache.fetchData([User].self, from: url)
 print("再次加载: \(cachedUsers.count) 个用户")

 print("缓存大小: \(networkCache.getCacheSize())")
 } catch {
 print("请求失败: \(error)")
 }
 }
 ```
 */
public class NetworkCacheService {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default

        // 配置缓存策略
        let cache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,    // 20MB 内存
            diskCapacity: 100 * 1024 * 1024,     // 100MB 磁盘
            diskPath: "network_cache"
        )
        config.urlCache = cache
        config.requestCachePolicy = .useProtocolCachePolicy

        session = URLSession(configuration: config)
    }

    func fetchData<T: Codable>(
        _ type: T.Type,
        from url: URL,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.cachePolicy = cachePolicy

        let (data, response) = try await session.data(for: request)

        // 检查是否来自缓存
        if let httpResponse = response as? HTTPURLResponse {
            let isFromCache = httpResponse.allHeaderFields["X-Cache"] != nil
            print(isFromCache ? "数据来自缓存" : "数据来自网络")
        }

        return try JSONDecoder().decode(type, from: data)
    }

    func clearCache() {
        session.configuration.urlCache?.removeAllCachedResponses()
    }

    func getCacheSize() -> String {
        guard let cache = session.configuration.urlCache else {
            return "0 MB"
        }

        let sizeInMB = Double(cache.currentMemoryUsage + cache.currentDiskUsage) / (1024 * 1024)
        return String(format: "%.2f MB", sizeInMB)
    }
}
