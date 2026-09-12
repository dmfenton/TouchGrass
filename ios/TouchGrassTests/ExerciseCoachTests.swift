import AVFoundation
import XCTest
@testable import TouchGrassMobile

final class ExerciseCoachTests: XCTestCase {
    @MainActor
    func testReadingUsesPlaybackAndStopClearsState() {
        let coach = ExerciseCoach()
        coach.speak("Let your shoulders relax. Look straight ahead and gently tuck your chin.")
        XCTAssertNil(coach.errorMessage)
        XCTAssertEqual(AVAudioSession.sharedInstance().category, .playback)
        XCTAssertEqual(AVAudioSession.sharedInstance().mode, .spokenAudio)
        XCTAssertTrue(coach.isSpeaking)
        coach.stop()
        XCTAssertFalse(coach.isSpeaking)
        coach.stop()
        XCTAssertFalse(coach.isSpeaking)
    }
}
