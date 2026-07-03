//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/12/2.
//

import Foundation

/// 内存缓存
/**

 缓存用户数据
 ```swift
let userCache = MemoryCache<Int, User>(maxItems: 50, ttl: 600)
 ```
存储用户到缓存
 ```swift
 userCache.set(user, forKey: user.id)
 ```

 从缓存获取用户
```swift
 if let cachedUser = userCache.get(forKey: 1) {
 print("从缓存获取用户: \(cachedUser.name)")
 } else {
 print("缓存中没有找到用户")
 }
 ```
*/
public class JQ_MemoryCache<Key: Hashable, Value> {
    private var cache: [Key: CacheItem] = [:]
    private let queue = DispatchQueue(label: "MemoryCache", attributes: .concurrent)
    private let maxItems: Int
    private let ttl: TimeInterval

    private struct CacheItem {
        let value: Value
        let timestamp: Date
    }

    public init(maxItems: Int = 100, ttl: TimeInterval = 300) {
        self.maxItems = maxItems
        self.ttl = ttl
    }

    public func set(_ value: Value, forKey key: Key) {
        queue.async(flags: .barrier) {
            // 检查缓存大小限制
            if self.cache.count >= self.maxItems {
                self.evictOldestItem()
            }

            self.cache[key] = CacheItem(value: value, timestamp: Date())
        }
    }

    public func get(forKey key: Key) -> Value? {
        return queue.sync {
            guard let item = cache[key] else { return nil }

            // 检查是否过期
            if Date().timeIntervalSince(item.timestamp) > ttl {
                cache.removeValue(forKey: key)
                return nil
            }

            return item.value
        }
    }

    private func evictOldestItem() {
        let oldestKey = cache.min { first, second in
            first.value.timestamp < second.value.timestamp
        }?.key

        if let key = oldestKey {
            cache.removeValue(forKey: key)
        }
    }

    public func clear() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
}
