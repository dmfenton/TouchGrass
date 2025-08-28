import XCTest
@testable import Touch_Grass

class StorageManagerTests: XCTestCase {
    var storageManager: StorageManager!
    let testFilename = "test_data.json"
    
    override func setUp() {
        super.setUp()
        storageManager = StorageManager.shared
        // Clean up any existing test file
        try? storageManager.deleteFile(testFilename)
    }
    
    override func tearDown() {
        // Clean up test file
        try? storageManager.deleteFile(testFilename)
        super.tearDown()
    }
    
    // MARK: - File Operations Tests
    
    func testFileURL() {
        let url = storageManager.fileURL(for: testFilename)
        XCTAssertTrue(url.path.contains("Application Support"))
        XCTAssertTrue(url.path.contains("Touch Grass"))
        XCTAssertTrue(url.lastPathComponent == testFilename)
    }
    
    func testSaveAndLoad() throws {
        // Create test data
        struct TestData: Codable, Equatable {
            let name: String
            let value: Int
            let date: Date
        }
        
        let testData = TestData(
            name: "Test",
            value: 42,
            date: Date()
        )
        
        // Save data
        try storageManager.save(testData, to: testFilename)
        
        // Verify file exists
        XCTAssertTrue(storageManager.fileExists(testFilename))
        
        // Load data
        let loadedData = try storageManager.load(TestData.self, from: testFilename)
        
        // Verify data matches
        XCTAssertEqual(loadedData.name, testData.name)
        XCTAssertEqual(loadedData.value, testData.value)
        XCTAssertEqual(
            loadedData.date.timeIntervalSinceReferenceDate,
            testData.date.timeIntervalSinceReferenceDate,
            accuracy: 0.001
        )
    }
    
    func testFileExists() {
        // File doesn't exist initially
        XCTAssertFalse(storageManager.fileExists(testFilename))
        
        // Create file
        let data = ["test": "value"]
        try? storageManager.save(data, to: testFilename)
        
        // File should exist now
        XCTAssertTrue(storageManager.fileExists(testFilename))
    }
    
    func testDeleteFile() throws {
        // Create a file
        let data = ["test": "value"]
        try storageManager.save(data, to: testFilename)
        XCTAssertTrue(storageManager.fileExists(testFilename))
        
        // Delete the file
        try storageManager.deleteFile(testFilename)
        
        // File should not exist
        XCTAssertFalse(storageManager.fileExists(testFilename))
    }
    
    func testDeleteNonExistentFile() {
        // Should not throw when deleting non-existent file
        XCTAssertNoThrow(try storageManager.deleteFile("non_existent.json"))
    }
    
    func testLoadNonExistentFile() {
        // Should throw when loading non-existent file
        struct TestData: Codable {
            let value: String
        }
        
        XCTAssertThrows(try storageManager.load(TestData.self, from: "non_existent.json"))
    }
    
    // MARK: - JSON Formatting Tests
    
    func testJSONFormatting() throws {
        // Create test data
        struct TestData: Codable {
            let name: String
            let values: [Int]
            let nested: NestedData
            
            struct NestedData: Codable {
                let flag: Bool
                let text: String
            }
        }
        
        let testData = TestData(
            name: "Test",
            values: [1, 2, 3],
            nested: TestData.NestedData(flag: true, text: "Hello")
        )
        
        // Save data
        try storageManager.save(testData, to: testFilename)
        
        // Read raw file
        let url = storageManager.fileURL(for: testFilename)
        let jsonString = try String(contentsOf: url)
        
        // Verify JSON is pretty printed
        XCTAssertTrue(jsonString.contains("\n"))
        XCTAssertTrue(jsonString.contains("  ")) // Indentation
        
        // Verify keys are sorted
        let lines = jsonString.components(separatedBy: "\n")
        let nameIndex = lines.firstIndex { $0.contains("\"name\"") } ?? -1
        let nestedIndex = lines.firstIndex { $0.contains("\"nested\"") } ?? -1
        let valuesIndex = lines.firstIndex { $0.contains("\"values\"") } ?? -1
        
        XCTAssertTrue(nameIndex < nestedIndex)
        XCTAssertTrue(nestedIndex < valuesIndex)
    }
    
    // MARK: - Date Encoding Tests
    
    func testDateEncoding() throws {
        struct DateTest: Codable {
            let timestamp: Date
        }
        
        let testDate = Date()
        let data = DateTest(timestamp: testDate)
        
        // Save and load
        try storageManager.save(data, to: testFilename)
        let loaded = try storageManager.load(DateTest.self, from: testFilename)
        
        // Dates should match exactly (ISO8601 preserves precision)
        XCTAssertEqual(
            loaded.timestamp.timeIntervalSinceReferenceDate,
            testDate.timeIntervalSinceReferenceDate,
            accuracy: 0.001
        )
        
        // Verify ISO8601 format in file
        let url = storageManager.fileURL(for: testFilename)
        let jsonString = try String(contentsOf: url)
        XCTAssertTrue(jsonString.contains("T")) // ISO8601 has T separator
        XCTAssertTrue(jsonString.contains("Z")) // ISO8601 has Z timezone
    }
    
    // MARK: - Migration Tests
    
    func testMigrateFromUserDefaults() {
        let migrationFilename = "migration_test.json"
        
        // Clean up any existing file
        try? storageManager.deleteFile(migrationFilename)
        
        // Set up UserDefaults data
        let defaults = UserDefaults.standard
        defaults.set("TestValue", forKey: "TestKey1")
        defaults.set(42, forKey: "TestKey2")
        defaults.set(true, forKey: "TestKey3")
        
        struct MigrationData: Codable {
            let stringValue: String
            let intValue: Int
            let boolValue: Bool
        }
        
        // Perform migration
        storageManager.migrateFromUserDefaults(
            MigrationData.self,
            keys: ["TestKey1", "TestKey2", "TestKey3"],
            to: migrationFilename
        ) { values in
            guard let string = values["TestKey1"] as? String,
                  let int = values["TestKey2"] as? Int,
                  let bool = values["TestKey3"] as? Bool else {
                return nil
            }
            return MigrationData(
                stringValue: string,
                intValue: int,
                boolValue: bool
            )
        }
        
        // Verify file was created
        XCTAssertTrue(storageManager.fileExists(migrationFilename))
        
        // Verify data was migrated correctly
        if let migrated = try? storageManager.load(MigrationData.self, from: migrationFilename) {
            XCTAssertEqual(migrated.stringValue, "TestValue")
            XCTAssertEqual(migrated.intValue, 42)
            XCTAssertEqual(migrated.boolValue, true)
        } else {
            XCTFail("Failed to load migrated data")
        }
        
        // Verify UserDefaults were cleaned up
        XCTAssertNil(defaults.object(forKey: "TestKey1"))
        XCTAssertNil(defaults.object(forKey: "TestKey2"))
        XCTAssertNil(defaults.object(forKey: "TestKey3"))
        
        // Clean up
        try? storageManager.deleteFile(migrationFilename)
    }
    
    func testMigrateFromUserDefaultsSkipsIfFileExists() {
        let migrationFilename = "existing_migration_test.json"
        
        // Create existing file
        let existingData = ["existing": "data"]
        try? storageManager.save(existingData, to: migrationFilename)
        
        // Set up UserDefaults data
        let defaults = UserDefaults.standard
        defaults.set("NewValue", forKey: "MigrationTestKey")
        
        struct MigrationData: Codable {
            let value: String
        }
        
        // Attempt migration
        storageManager.migrateFromUserDefaults(
            MigrationData.self,
            keys: ["MigrationTestKey"],
            to: migrationFilename
        ) { values in
            guard let value = values["MigrationTestKey"] as? String else {
                return nil
            }
            return MigrationData(value: value)
        }
        
        // Verify UserDefaults were NOT cleaned up (migration was skipped)
        XCTAssertNotNil(defaults.object(forKey: "MigrationTestKey"))
        
        // Clean up
        defaults.removeObject(forKey: "MigrationTestKey")
        try? storageManager.deleteFile(migrationFilename)
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentSaveAndLoad() {
        let expectation = self.expectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 20
        
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        
        for i in 0..<10 {
            // Save operations
            queue.async {
                let data = ["iteration": i]
                try? self.storageManager.save(data, to: "concurrent_\(i).json")
                expectation.fulfill()
            }
            
            // Load operations (after a small delay)
            queue.asyncAfter(deadline: .now() + 0.1) {
                _ = try? self.storageManager.load(
                    [String: Int].self,
                    from: "concurrent_\(i).json"
                )
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5)
        
        // Clean up
        for i in 0..<10 {
            try? storageManager.deleteFile("concurrent_\(i).json")
        }
    }
    
    // MARK: - Edge Cases
    
    func testLargeDataSaveAndLoad() throws {
        struct LargeData: Codable {
            let values: [String]
        }
        
        // Create large dataset (1MB+)
        var values: [String] = []
        for i in 0..<10000 {
            values.append(String(repeating: "x", count: 100) + "\(i)")
        }
        
        let largeData = LargeData(values: values)
        
        // Should handle large data
        try storageManager.save(largeData, to: "large_data.json")
        let loaded = try storageManager.load(LargeData.self, from: "large_data.json")
        
        XCTAssertEqual(loaded.values.count, values.count)
        XCTAssertEqual(loaded.values.first, values.first)
        XCTAssertEqual(loaded.values.last, values.last)
        
        // Clean up
        try? storageManager.deleteFile("large_data.json")
    }
    
    func testSpecialCharactersInFilename() throws {
        let specialFilename = "test-file_2024.01.01@12:00.json"
        let data = ["test": "value"]
        
        // Should handle special characters
        try storageManager.save(data, to: specialFilename)
        XCTAssertTrue(storageManager.fileExists(specialFilename))
        
        let loaded = try storageManager.load([String: String].self, from: specialFilename)
        XCTAssertEqual(loaded["test"], "value")
        
        // Clean up
        try? storageManager.deleteFile(specialFilename)
    }
}