//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/12/2.
//

import Foundation



/// UserDefault缓存
/**

 初始化
 ```swift
 let settingsCache = UserDefaultsCache()
 ```
保存
 ```swift
 let settings = AppSettings(
 theme: "dark",
 language: "zh-CN",
 notifications: true
 )

 settingsCache.save(settings, forKey: "app_settings")
 ```

 加载设置
 ```swift
 if let loadedSettings = settingsCache.load(AppSettings.self, forKey: "app_settings") {
 print("加载设置: 主题=\(loadedSettings.theme), 语言=\(loadedSettings.language)")
 }
 ```

 */
public class JQ_UserDefaultsCache {
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public func save<T: Codable>(_ object: T, forKey key: String) {
        do {
            let data = try encoder.encode(object)
            userDefaults.set(data, forKey: key)
        } catch {
            print("保存到 UserDefaults 失败: \(error)")
        }
    }

    public func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }

        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("从 UserDefaults 加载失败: \(error)")
            return nil
        }
    }

    public func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }

    public func exists(forKey key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }
}
