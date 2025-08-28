import Foundation

class StorageManager {
    static let shared = StorageManager()
    
    private let applicationSupportURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        // Get Application Support directory
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access Application Support directory")
        }
        self.applicationSupportURL = appSupportURL.appendingPathComponent("Touch Grass")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: applicationSupportURL, withIntermediateDirectories: true)
        
        // Set up encoder/decoder
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - File Operations
    
    func fileURL(for filename: String) -> URL {
        return applicationSupportURL.appendingPathComponent(filename)
    }
    
    func save<T: Encodable>(_ object: T, to filename: String) throws {
        let url = fileURL(for: filename)
        let data = try encoder.encode(object)
        try data.write(to: url)
    }
    
    func load<T: Decodable>(_ type: T.Type, from filename: String) throws -> T {
        let url = fileURL(for: filename)
        let data = try Data(contentsOf: url)
        return try decoder.decode(type, from: data)
    }
    
    func fileExists(_ filename: String) -> Bool {
        return FileManager.default.fileExists(atPath: fileURL(for: filename).path)
    }
    
    func deleteFile(_ filename: String) throws {
        let url = fileURL(for: filename)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Migration from UserDefaults
    
    func migrateFromUserDefaults<T: Codable>(_ type: T.Type,
                                             keys: [String],
                                             to filename: String,
                                             builder: ([String: Any]) -> T?) {
        // Check if file already exists
        if fileExists(filename) { return }
        
        // Try to load from UserDefaults
        var values: [String: Any] = [:]
        for key in keys {
            if let value = UserDefaults.standard.object(forKey: key) {
                values[key] = value
            }
        }
        
        // Build object and save
        if !values.isEmpty, let object = builder(values) {
            try? save(object, to: filename)
            
            // Clean up UserDefaults
            for key in keys {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}
