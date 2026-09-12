import XCTest
@testable import TouchGrassMobile

final class WeatherRefreshTests: XCTestCase {
    func testRefreshesImmediatelyAndWhenStaleButNotRepeatedly() {
        let now = Date()
        XCTAssertTrue(WeatherRefreshPolicy.shouldRefresh(now: now, lastAttempt: nil, lastSuccess: nil))
        XCTAssertFalse(WeatherRefreshPolicy.shouldRefresh(now: now, lastAttempt: now, lastSuccess: nil))
        XCTAssertTrue(WeatherRefreshPolicy.shouldRefresh(now: now.addingTimeInterval(60), lastAttempt: now, lastSuccess: nil))
        XCTAssertFalse(WeatherRefreshPolicy.shouldRefresh(now: now.addingTimeInterval(899), lastAttempt: now, lastSuccess: now))
        XCTAssertTrue(WeatherRefreshPolicy.shouldRefresh(now: now.addingTimeInterval(900), lastAttempt: now, lastSuccess: now))
    }

    func testWeatherTemperatureUsesWholeDegreesAndLocale() {
        let temperature = Measurement(value: 26.565396, unit: UnitTemperature.celsius)
        let us = WeatherRefreshPolicy.temperature(temperature, locale: Locale(identifier: "en_US"))
        let france = WeatherRefreshPolicy.temperature(temperature, locale: Locale(identifier: "fr_FR"))
        XCTAssertTrue(us.contains("80"), us)
        XCTAssertFalse(us.contains("."), us)
        XCTAssertTrue(france.contains("27"), france)
        XCTAssertFalse(france.contains(","), france)
    }
}
