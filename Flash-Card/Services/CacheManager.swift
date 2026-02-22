import Foundation

/**
 CacheManager: A lightweight utility to persist API responses locally.
 Used to provide an "offline-first" experience by showing last-cached data
 when the network fails.
 */
class CacheManager {
    static let shared = CacheManager()
    private let userDefaults = UserDefaults.standard
    private let prefix = "api_cache_"
    
    private init() {}
    
    /// Saves a Codable object to disk
    func save<T: Encodable>(_ object: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(object)
            userDefaults.set(data, forKey: prefix + key)
        } catch {
            print("[CacheManager] ❌ Failed to save \(key): \(error.localizedDescription)")
        }
    }
    
    /// Loads a Codable object from disk
    func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: prefix + key) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("[CacheManager] ❌ Failed to load \(key): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Clears a specific cache entry
    func clear(forKey key: String) {
        userDefaults.removeObject(forKey: prefix + key)
    }
}
