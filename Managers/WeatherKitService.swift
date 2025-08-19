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
    case sunny = "sunny"
    case partlyCloudy = "partlyCloudy"
    case cloudy = "cloudy"
    case rainy = "rainy"
    case heavyRain = "heavyRain"
    case snowy = "snowy"
    case foggy = "foggy"
    case windy = "windy"
    case unknown = "unknown"
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
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        
        // Request location permissions if needed
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        // Get current location
        locationManager.requestLocation()
    }
    
    // MARK: - Async Weather Fetching
    func getCurrentWeather() async -> WeatherInfo? {
        // Check cache first
        if let cached = getCachedWeather() {
            return cached
        }
        
        // Get location
        guard let location = await getCurrentLocation() else {
            print("⚠️ WeatherKit: No location available")
            return nil
        }
        
        do {
            // Fetch weather from WeatherKit
            let weather = try await weatherService.weather(for: location)
            
            // Convert to our model
            let weatherInfo = convertToWeatherInfo(weather)
            
            // Cache the result
            cacheWeather(weatherInfo)
            
            return weatherInfo
        } catch {
            print("⚠️ WeatherKit error: \(error)")
            return nil
        }
    }
    
    // MARK: - Sync Weather Fetching (for backward compatibility)
    func getCurrentWeatherSync() -> WeatherInfo? {
        // Return cached weather if available
        return getCachedWeather()
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
        let isDaylight = current.isDaylight ?? true
        
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
        case .fog, .haze, .smoky:
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
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("⚠️ Location error: \(error)")
        // Use default location as fallback
        let defaultLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        currentLocation = defaultLocation
        locationContinuation?.resume(returning: defaultLocation)
        locationContinuation = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            print("⚠️ Location access denied")
            // Use default location
            let defaultLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
            currentLocation = defaultLocation
        default:
            break
        }
    }
}

// MARK: - Fallback Service for macOS < 13.0
class FallbackWeatherService: WeatherServiceProtocol {
    func getCurrentWeather() async -> WeatherInfo? {
        // Return moderate weather as fallback
        return WeatherInfo(
            temperature: 65,
            condition: .partlyCloudy,
            isDaylight: true,
            description: "Partly cloudy",
            humidity: 0.5,
            feelsLike: 65
        )
    }
    
    func getCurrentWeatherSync() -> WeatherInfo? {
        return WeatherInfo(
            temperature: 65,
            condition: .partlyCloudy,
            isDaylight: true,
            description: "Partly cloudy",
            humidity: 0.5,
            feelsLike: 65
        )
    }
}

// MARK: - Factory
class WeatherServiceFactory {
    static func create() -> WeatherServiceProtocol {
        if #available(macOS 13.0, *) {
            return WeatherKitService()
        } else {
            return FallbackWeatherService()
        }
    }
}