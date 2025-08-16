import Foundation

final class TestPreferencesStore {
    private var storage: [String: Any] = [:]
    private let queue = DispatchQueue(label: "TestPreferencesStore")
    
    func setValue(_ value: Any?, forKey key: String) {
        queue.sync {
            if let value = value {
                storage[key] = value
            } else {
                storage.removeValue(forKey: key)
            }
        }
    }
    
    func value(forKey key: String) -> Any? {
        queue.sync {
            return storage[key]
        }
    }
    
    func bool(forKey key: String) -> Bool {
        return value(forKey: key) as? Bool ?? false
    }
    
    func integer(forKey key: String) -> Int {
        return value(forKey: key) as? Int ?? 0
    }
    
    func double(forKey key: String) -> Double {
        return value(forKey: key) as? Double ?? 0.0
    }
    
    func string(forKey key: String) -> String? {
        return value(forKey: key) as? String
    }
    
    func array(forKey key: String) -> [Any]? {
        return value(forKey: key) as? [Any]
    }
    
    func dictionary(forKey key: String) -> [String: Any]? {
        return value(forKey: key) as? [String: Any]
    }
    
    func reset() {
        queue.sync {
            storage.removeAll()
        }
    }
    
    func synchronize() -> Bool {
        return true
    }
}