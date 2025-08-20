import Foundation
import WeatherKit
import CoreLocation

// MARK: - Weather Data Model
struct WeatherInfo: Codable {
    let temperature: Double // Fahrenheit
    let condition: WeatherCondition
    let isDaylight: Bool
    let description: String
    let humidity: Double
    let feelsLike: Double
    
    var isIdealForOutdoor: Bool {
        // Ideal outdoor conditions: 50-80°F, not raining/snowing, daylight
        return temperature >= 50 && 
               temperature <= 80 && 
               condition != .rainy && 
               condition != .snowy && 
               isDaylight
    }
    
    var isGoodForOutdoor: Bool {
        // Acceptable outdoor conditions: 40-85°F, not heavy rain/snow
        return temperature >= 40 && 
               temperature <= 85 && 
               condition != .heavyRain && 
               condition != .snowy && 
               isDaylight
    }
}

enum WeatherCondition: String, Codable {
    case sunny
    case partlyCloudy
    case cloudy
    case rainy
    case heavyRain
    case snowy
    case foggy
    case windy
    case unknown
}

// MARK: - Protocol for Testing
protocol WeatherServiceProtocol {
    func getCurrentWeather() async -> WeatherInfo?
    func getCurrentWeatherSync() -> WeatherInfo?
}

// MARK: - WeatherKit Service Implementation
@available(macOS 13.0, *)
class WeatherKitService: NSObject, WeatherServiceProtocol {
    private let weatherService = WeatherService()
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    // Cache weather data for 30 minutes to avoid excessive API calls
    private var cachedWeather: WeatherInfo?
    private var cacheTimestamp: Date?
    private let cacheTimeout: TimeInterval = 1800 // 30 minutes
    
    // Simple file logging for debugging
    private func logToFile(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        let logMessage = "[\(timestamp)] \(message)\n"
        
        let logURL = URL(fileURLWithPath: "/tmp/touchgrass_debug.log")
        
        if let data = logMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logURL)
            }
        }
    }
    
    override init() {
        super.init()
        NSLog("🔍 [WeatherKit] Initializing WeatherKitService")
        logToFile("🔍 [WeatherKit] Initializing WeatherKitService")
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        NSLog("🔍 [WeatherKit] setupLocationManager called")
        logToFile("🔍 [WeatherKit] setupLocationManager called")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        
        let status = locationManager.authorizationStatus
        NSLog("🔍 [WeatherKit] Location authorization status: \(status.rawValue)")
        logToFile("🔍 [WeatherKit] Location authorization status: \(status.rawValue)")
        
        // For macOS, we need to actively request permission and location
        switch status {
        case .notDetermined:
            NSLog("🔍 [WeatherKit] Requesting location permission...")
            logToFile("🔍 [WeatherKit] Requesting location permission...")
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            NSLog("🔍 [WeatherKit] Have location permission, requesting location...")
            logToFile("🔍 [WeatherKit] Have location permission, requesting location...")
            locationManager.requestLocation()
            // Also immediately try to cache weather
            Task {
                logToFile("🔍 [WeatherKit] Attempting to pre-cache weather with current location")
                if let weather = await getCurrentWeather() {
                    logToFile("🔍 [WeatherKit] Successfully pre-cached weather: \(Int(weather.temperature))°F")
                } else {
                    logToFile("🔍 [WeatherKit] Failed to pre-cache weather")
                }
            }
        case .denied, .restricted:
            NSLog("🔍 [WeatherKit] Location denied/restricted, using default location")
            logToFile("🔍 [WeatherKit] Location denied/restricted, using default location")
            let defaultLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
            currentLocation = defaultLocation
            // Try to fetch weather with default location immediately
            Task {
                _ = await getCurrentWeather()
            }
        default:
            NSLog("🔍 [WeatherKit] Unhandled location status: \(status.rawValue)")
            logToFile("🔍 [WeatherKit] Unhandled location status: \(status.rawValue)")
        }
    }
    
    // MARK: - Async Weather Fetching
    func getCurrentWeather() async -> WeatherInfo? {
        NSLog("🔍 [WeatherKit] getCurrentWeather (async) called")
        
        // Check cache first
        if let cached = getCachedWeather() {
            NSLog("🔍 [WeatherKit] Returning cached weather from async method")
            return cached
        }
        
        NSLog("🔍 [WeatherKit] No cache, fetching location...")
        // Get location
        guard let location = await getCurrentLocation() else {
            NSLog("⚠️ WeatherKit: No location available")
            return nil
        }
        NSLog("🔍 [WeatherKit] Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        do {
            NSLog("🔍 [WeatherKit] Fetching weather from WeatherKit API...")
            logToFile("🔍 [WeatherKit] Fetching weather from WeatherKit API for location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            
            // Fetch weather from WeatherKit
            let weather = try await weatherService.weather(for: location)
            
            NSLog("🔍 [WeatherKit] Weather fetched successfully")
            logToFile("🔍 [WeatherKit] Weather fetched successfully")
            
            // Convert to our model
            let weatherInfo = convertToWeatherInfo(weather)
            
            NSLog("🔍 [WeatherKit] Caching weather: \(Int(weatherInfo.temperature))°F")
            logToFile("🔍 [WeatherKit] Caching weather: \(Int(weatherInfo.temperature))°F, condition: \(weatherInfo.condition)")
            
            // Cache the result
            cacheWeather(weatherInfo)
            
            return weatherInfo
        } catch {
            NSLog("⚠️ WeatherKit error: \(error.localizedDescription)")
            logToFile("⚠️ WeatherKit DETAILED ERROR:")
            logToFile("   Error: \(error)")
            logToFile("   LocalizedDescription: \(error.localizedDescription)")
            
            if let nsError = error as NSError? {
                logToFile("   Domain: \(nsError.domain)")
                logToFile("   Code: \(nsError.code)")
                logToFile("   UserInfo: \(nsError.userInfo)")
            }
            
            return nil
        }
    }
    
    // MARK: - Sync Weather Fetching (for backward compatibility)
    func getCurrentWeatherSync() -> WeatherInfo? {
        NSLog("🔍 [WeatherKit] getCurrentWeatherSync called")
        logToFile("🔍 [WeatherKit] getCurrentWeatherSync called")
        
        // Check cache first
        if let cached = getCachedWeather() {
            NSLog("🔍 [WeatherKit] Returning cached weather: \(Int(cached.temperature))°F")
            logToFile("🔍 [WeatherKit] Returning cached weather: \(Int(cached.temperature))°F")
            return cached
        }
        
        NSLog("🔍 [WeatherKit] No cached weather available")
        logToFile("🔍 [WeatherKit] No cached weather available")
        NSLog("🔍 [WeatherKit] Current location: \(currentLocation?.coordinate.latitude ?? -999), \(currentLocation?.coordinate.longitude ?? -999)")
        logToFile("🔍 [WeatherKit] Current location: \(currentLocation?.coordinate.latitude ?? -999), \(currentLocation?.coordinate.longitude ?? -999)")
        NSLog("🔍 [WeatherKit] Authorization status: \(locationManager.authorizationStatus.rawValue)")
        logToFile("🔍 [WeatherKit] Authorization status: \(locationManager.authorizationStatus.rawValue)")
        
        // Since this is sync, we can't fetch new weather
        // Return nil - the async version should be used for fetching
        NSLog("🔍 [WeatherKit] Sync method cannot fetch new weather - returning nil")
        logToFile("🔍 [WeatherKit] Sync method cannot fetch new weather - returning nil")
        return nil
    }
    
    // MARK: - Location Handling
    private func getCurrentLocation() async -> CLLocation? {
        // If we have a recent location, use it
        if let location = currentLocation {
            return location
        }
        
        // Otherwise request a new one
        return await withCheckedContinuation { continuation in
            locationManager.requestLocation()
            
            // Set up a timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                if self?.currentLocation == nil {
                    // Use a default location (San Francisco) as fallback
                    let defaultLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
                    continuation.resume(returning: defaultLocation)
                }
            }
            
            // This will be called from the delegate
            self.locationContinuation = continuation
        }
    }
    
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    
    // MARK: - Weather Conversion
    private func convertToWeatherInfo(_ weather: Weather) -> WeatherInfo {
        let current = weather.currentWeather
        
        // Convert temperature to Fahrenheit
        let tempF = current.temperature.converted(to: .fahrenheit).value
        
        // Determine weather condition
        let condition = mapWeatherCondition(current.condition)
        
        // Check if daylight
        let isDaylight = current.isDaylight
        
        // Get feels like temperature
        let feelsLikeF = current.apparentTemperature.converted(to: .fahrenheit).value
        
        return WeatherInfo(
            temperature: tempF,
            condition: condition,
            isDaylight: isDaylight,
            description: current.condition.description,
            humidity: current.humidity,
            feelsLike: feelsLikeF
        )
    }
    
    private func mapWeatherCondition(_ condition: WeatherKit.WeatherCondition) -> WeatherCondition {
        switch condition {
        case .clear, .mostlyClear:
            return .sunny
        case .partlyCloudy:
            return .partlyCloudy
        case .cloudy, .mostlyCloudy:
            return .cloudy
        case .drizzle, .rain:
            return .rainy
        case .heavyRain, .thunderstorms, .strongStorms:
            return .heavyRain
        case .snow, .sleet, .hail:
            return .snowy
        case .foggy, .haze, .smoky:
            return .foggy
        case .windy, .breezy:
            return .windy
        default:
            return .unknown
        }
    }
    
    // MARK: - Caching
    private func getCachedWeather() -> WeatherInfo? {
        guard let cached = cachedWeather,
              let timestamp = cacheTimestamp,
              Date().timeIntervalSince(timestamp) < cacheTimeout else {
            return nil
        }
        return cached
    }
    
    private func cacheWeather(_ weather: WeatherInfo) {
        cachedWeather = weather
        cacheTimestamp = Date()
    }
}

// MARK: - Location Manager Delegate
@available(macOS 13.0, *)
extension WeatherKitService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location
            logToFile("🔍 [WeatherKit] Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            
            // Trigger weather caching when we get location
            Task {
                logToFile("🔍 [WeatherKit] Location received, fetching weather...")
                if let weather = await getCurrentWeather() {
                    logToFile("🔍 [WeatherKit] Weather cached after location update: \(Int(weather.temperature))°F")
                } else {
                    logToFile("🔍 [WeatherKit] Failed to fetch weather after location update")
                }
            }
            
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("⚠️ Location error: \(error.localizedDescription)")
        // Use default location as fallback
        let defaultLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        currentLocation = defaultLocation
        locationContinuation?.resume(returning: defaultLocation)
        locationContinuation = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        NSLog("🔍 [WeatherKit] Authorization changed to: \(manager.authorizationStatus.rawValue)")
        switch manager.authorizationStatus {
        case .authorizedAlways:
            NSLog("🔍 [WeatherKit] Got location permission, requesting location...")
            manager.requestLocation()
        case .denied, .restricted:
            NSLog("⚠️ Location access denied - using default location")
            // Use default location (San Francisco)
            let defaultLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
            currentLocation = defaultLocation
            // Trigger a weather fetch with the default location
            Task {
                _ = await getCurrentWeather()
            }
            default:
            NSLog("🔍 [WeatherKit] Authorization status: \(manager.authorizationStatus.rawValue)")
        }
    }
}

// MARK: - NWS Weather Service (Public API)
class NWSWeatherService: NSObject, WeatherServiceProtocol {
    static let shared = NWSWeatherService()
    
    private let session = URLSession.shared
    private var cachedWeather: WeatherInfo?
    private var cacheTimestamp: Date?
    private let cacheTimeout: TimeInterval = 1800 // 30 minutes
    
    // Location services
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private var hasRequestedLocationPermission = false
    
    private func logToFile(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        let logMessage = "[\(timestamp)] \(message)\n"
        
        let logURL = URL(fileURLWithPath: "/tmp/touchgrass_debug.log")
        
        if let data = logMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logURL)
            }
        }
    }
    
    private override init() {
        super.init()
        NSLog("🔍 [NWSWeather] Using National Weather Service API (singleton)")
        logToFile("🔍 [NWSWeather] Using National Weather Service API (singleton)")
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        logToFile("🔍 [NWSWeather] Setting up location manager")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        
        let status = locationManager.authorizationStatus
        logToFile("🔍 [NWSWeather] Location authorization status: \(status.rawValue) (\(authStatusDescription(status)))")
        
        switch status {
        case .notDetermined:
            logToFile("🔍 [NWSWeather] Requesting location permission...")
            // Request "when in use" which is more likely to be granted persistently
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            logToFile("🔍 [NWSWeather] Already have location permission, requesting location...")
            locationManager.requestLocation()
        case .denied, .restricted:
            logToFile("🔍 [NWSWeather] Location denied/restricted - no weather available")
            currentLocation = nil
        @unknown default:
            logToFile("🔍 [NWSWeather] Unknown location status: \(status.rawValue)")
        }
    }
    
    private func authStatusDescription(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "authorizedAlways"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        @unknown default: return "unknown"
        }
    }
    
    func getCurrentWeather() async -> WeatherInfo? {
        logToFile("🔍 [NWSWeather] getCurrentWeather called")
        
        // Check cache first
        if let cached = getCachedWeather() {
            logToFile("🔍 [NWSWeather] Returning cached weather: \(Int(cached.temperature))°F")
            return cached
        }
        
        // Require actual location - no hardcoded fallback
        guard let location = currentLocation else {
            logToFile("🔍 [NWSWeather] No location available - cannot fetch weather")
            return nil
        }
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        logToFile("🔍 [NWSWeather] Using location: \(lat), \(lon)")
        
        do {
            // Step 1: Get the forecast office and grid coordinates
            guard let pointsURL = URL(string: "https://api.weather.gov/points/\(lat),\(lon)") else {
                logToFile("🔍 [NWSWeather] Invalid URL for points")
                return nil
            }
            logToFile("🔍 [NWSWeather] Fetching grid info from: \(pointsURL)")
            
            let (pointsData, _) = try await session.data(from: pointsURL)
            let pointsResponse = try JSONDecoder().decode(NWSPointsResponse.self, from: pointsData)
            
            // Step 2: Get current conditions from the nearest station
            if let stationsURL = URL(string: pointsResponse.properties.observationStations) {
                logToFile("🔍 [NWSWeather] Fetching stations from: \(stationsURL)")
                let (stationsData, _) = try await session.data(from: stationsURL)
                let stationsResponse = try JSONDecoder().decode(NWSStationsResponse.self, from: stationsData)
                
                // Get observations from the first station  
                if let firstStationURL = stationsResponse.features.first?.id {
                    // Extract just the station ID from the URL
                    let stationID = firstStationURL.components(separatedBy: "/").last ?? "SFOC1"
                    guard let obsURL = URL(string: "https://api.weather.gov/stations/\(stationID)/observations/latest") else {
                        logToFile("🔍 [NWSWeather] Invalid URL for observations")
                        return nil
                    }
                    logToFile("🔍 [NWSWeather] Fetching observations from: \(obsURL)")
                    
                    let (obsData, _) = try await session.data(from: obsURL)
                    let obsResponse = try JSONDecoder().decode(NWSObservationResponse.self, from: obsData)
                    
                    let weather = convertNWSToWeatherInfo(obsResponse.properties)
                    cacheWeather(weather)
                    logToFile("🔍 [NWSWeather] Successfully fetched weather: \(Int(weather.temperature))°F")
                    return weather
                }
            }
        } catch {
            logToFile("🔍 [NWSWeather] Error fetching weather: \(error)")
        }
        
        // Fallback to default weather
        let fallback = WeatherInfo(
            temperature: 65,
            condition: .partlyCloudy,
            isDaylight: true,
            description: "Partly cloudy",
            humidity: 0.6,
            feelsLike: 65
        )
        logToFile("🔍 [NWSWeather] Using fallback weather")
        return fallback
    }
    
    func getCurrentWeatherSync() -> WeatherInfo? {
        logToFile("🔍 [NWSWeather] getCurrentWeatherSync called")
        
        // Return cached weather if available
        if let cached = getCachedWeather() {
            logToFile("🔍 [NWSWeather] Returning cached weather: \(Int(cached.temperature))°F")
            return cached
        }
        
        logToFile("🔍 [NWSWeather] No cached weather, returning nil for sync call")
        return nil
    }
    
    private func getCachedWeather() -> WeatherInfo? {
        guard let cached = cachedWeather,
              let timestamp = cacheTimestamp,
              Date().timeIntervalSince(timestamp) < cacheTimeout else {
            return nil
        }
        return cached
    }
    
    private func cacheWeather(_ weather: WeatherInfo) {
        cachedWeather = weather
        cacheTimestamp = Date()
    }
    
    private func convertNWSToWeatherInfo(_ props: NWSObservationProperties) -> WeatherInfo {
        // Convert Celsius to Fahrenheit if needed
        let tempF = if let tempC = props.temperature.value {
            (tempC * 9 / 5) + 32
        } else {
            65.0 // fallback
        }
        
        let condition = mapNWSCondition(props.textDescription)
        
        logToFile("🔍 [NWSWeather] Raw description: '\(props.textDescription ?? "nil")'")
        logToFile("🔍 [NWSWeather] Mapped condition: \(condition)")
        
        return WeatherInfo(
            temperature: tempF,
            condition: condition,
            isDaylight: true, // Simplified for now
            description: props.textDescription ?? "Clear",
            humidity: props.relativeHumidity.value ?? 0.5,
            feelsLike: tempF
        )
    }
    
    private func mapNWSCondition(_ description: String?) -> WeatherCondition {
        guard let desc = description?.lowercased() else { return .partlyCloudy }
        
        if desc.contains("clear") || desc.contains("sunny") {
            return .sunny
        } else if desc.contains("rain") || desc.contains("shower") {
            return .rainy
        } else if desc.contains("snow") {
            return .snowy
        } else if desc.contains("fog") {
            return .foggy
        } else if desc.contains("wind") {
            return .windy
        } else if desc.contains("cloud") {
            return .cloudy
        } else {
            return .partlyCloudy
        }
    }
}

// MARK: - NWS Location Manager Delegate
extension NWSWeatherService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location
            logToFile("🔍 [NWSWeather] Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            
            // Clear cache when location changes so we fetch weather for new location
            cachedWeather = nil
            cacheTimestamp = nil
            
            // Trigger weather fetch for new location
            Task {
                _ = await getCurrentWeather()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logToFile("🔍 [NWSWeather] Location error: \(error.localizedDescription)")
        logToFile("🔍 [NWSWeather] No fallback location - weather unavailable")
        currentLocation = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        logToFile("🔍 [NWSWeather] Authorization changed to: \(manager.authorizationStatus.rawValue)")
        switch manager.authorizationStatus {
        case .authorizedAlways:
            logToFile("🔍 [NWSWeather] Got location permission, requesting location...")
            manager.requestLocation()
        case .denied, .restricted:
            logToFile("🔍 [NWSWeather] Location access denied - weather unavailable")
            currentLocation = nil
            default:
            logToFile("🔍 [NWSWeather] Authorization status: \(manager.authorizationStatus.rawValue)")
        }
    }
}

// MARK: - NWS API Models
struct NWSPointsResponse: Codable {
    let properties: NWSPointsProperties
}

struct NWSPointsProperties: Codable {
    let observationStations: String
}

struct NWSStationsResponse: Codable {
    let features: [NWSStation]
}

struct NWSStation: Codable {
    let id: String
}

struct NWSObservationResponse: Codable {
    let properties: NWSObservationProperties
}

struct NWSObservationProperties: Codable {
    let temperature: NWSValue
    let relativeHumidity: NWSValue
    let textDescription: String?
}

struct NWSValue: Codable {
    let value: Double?
}

// MARK: - Factory
class WeatherServiceFactory {
    static func create() -> WeatherServiceProtocol {
        NSLog("🔍 [WeatherServiceFactory] Using NWSWeatherService singleton")
        return NWSWeatherService.shared
    }
}
