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

    override init() {
        super.init()
        location.delegate = self
        location.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func refresh() {
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
                state = .ready(weather, attribution)
            } catch { state = .unavailable("Weather is unavailable right now. Try again later.") }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        state = .unavailable("Your location is unavailable. Try again later.")
    }
}

struct OutdoorWeatherView: View {
    @StateObject private var weather = OutdoorWeather()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        FentonCard {
            VStack(alignment: .leading, spacing: FentonSpacing.medium) {
                switch weather.state {
                case .idle:
                    Button("Check outdoor weather", systemImage: "cloud.sun") { weather.refresh() }
                case .loading:
                    ProgressView("Checking the weather…")
                case .unavailable(let message):
                    Text(message).foregroundStyle(.secondary)
                    Button("Try weather again") { weather.refresh() }
                case .ready(let current, let attribution):
                    Label(current.temperature.formatted(), systemImage: current.symbolName).font(.title2)
                    Text(current.condition.description)
                    let markURL = colorScheme == .dark ? attribution.combinedMarkLightURL : attribution.combinedMarkDarkURL
                    HStack {
                        AsyncImage(url: markURL) { image in
                            image.resizable().scaledToFit()
                        } placeholder: { Text("Apple Weather") }
                            .frame(width: 100, height: 20)
                            .accessibilityLabel("Apple Weather")
                        Link("Data sources", destination: attribution.legalPageURL).font(.caption)
                    }
                    Button("Refresh weather") { weather.refresh() }
                }
            }
        }
    }
}
