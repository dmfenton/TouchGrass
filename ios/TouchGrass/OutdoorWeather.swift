import CoreLocation
import FentonDesignSystem
import SwiftUI
import WeatherKit

@MainActor
final class OutdoorWeather: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    enum State {
        case idle
        case loading
        case ready(CurrentWeather, WeatherAttribution)
        case unavailable(String)
    }
    @Published private(set) var state = State.idle
    private let location = CLLocationManager()
    private var lastAttempt: Date?
    private var lastSuccess: Date?

    func refreshIfNeeded(now: Date = Date()) {
        guard !ProcessInfo.processInfo.arguments.contains("--ui-testing") else { return }
        guard WeatherRefreshPolicy.shouldRefresh(now: now, lastAttempt: lastAttempt, lastSuccess: lastSuccess) else { return }
        if case .loading = state { return }
        refresh()
    }

    override init() {
        super.init()
        location.delegate = self
        location.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func refresh() {
        lastAttempt = Date()
        state = .loading
        switch location.authorizationStatus {
        case .notDetermined: location.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: location.requestLocation()
        case .denied, .restricted: state = .unavailable("Location access is off. Weather is optional.")
        @unknown default: state = .unavailable("Location is unavailable.")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard case .loading = state else { return }
        if manager.authorizationStatus != .notDetermined { refresh() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last else {
            state = .unavailable("Your location is unavailable. Try again outdoors.")
            return
        }
        Task {
            do {
                let weather = try await WeatherService.shared.weather(for: coordinate, including: .current)
                let attribution = try await WeatherService.shared.attribution
                lastSuccess = Date()
                state = .ready(weather, attribution)
            } catch { state = .unavailable("Weather is unavailable right now. Try again later.") }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        state = .unavailable("Your location is unavailable. Try again later.")
    }
}

enum WeatherRefreshPolicy {
    static func shouldRefresh(now: Date, lastAttempt: Date?, lastSuccess: Date?) -> Bool {
        if let lastSuccess, now.timeIntervalSince(lastSuccess) < 900 { return false }
        if let lastAttempt, now.timeIntervalSince(lastAttempt) < 60 { return false }
        return true
    }

    static func temperature(_ value: Measurement<UnitTemperature>, locale: Locale = .current) -> String {
        value.formatted(.measurement(width: .abbreviated, usage: .weather,
                                     numberFormatStyle: .number.precision(.fractionLength(0))).locale(locale))
    }
}

struct OutdoorWeatherView: View {
    @StateObject private var weather = OutdoorWeather()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: FentonSpacing.small) {
            switch weather.state {
            case .idle, .loading:
                Label("Checking outdoor weather…", systemImage: "cloud.sun")
                    .foregroundStyle(.secondary)
            case .unavailable(let message):
                HStack(alignment: .top) {
                    Text(message).font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Button("Retry") { weather.refresh() }
                }
            case .ready(let current, let attribution):
                HStack(alignment: .firstTextBaseline) {
                    Label(WeatherRefreshPolicy.temperature(current.temperature), systemImage: current.symbolName)
                        .font(.title2.weight(.semibold))
                    Text(current.condition.description).foregroundStyle(.secondary)
                }
                let markURL = colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL
                HStack(spacing: FentonSpacing.medium) {
                    AsyncImage(url: markURL) { image in
                        image.resizable().scaledToFit()
                    } placeholder: { Text("Apple Weather").font(.caption) }
                        .frame(width: 84, height: 16).accessibilityLabel("Apple Weather")
                    Link("Data sources", destination: attribution.legalPageURL).font(.caption)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                weather.refreshIfNeeded()
                do { try await Task.sleep(for: .seconds(60)) } catch { return }
            }
        }
    }
}
