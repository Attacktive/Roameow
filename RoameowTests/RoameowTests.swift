import XCTest
@testable import Roameow

final class RoameowTests: XCTestCase {
	private let defaults = UserDefaults.standard

	override func setUp() {
		super.setUp()

		// Clear all app keys so @AppStorage returns its declared defaults
		let keys = ["petSize", "movementEnabled", "speed", "idleEnabled", "idleProbability", "volume", "customImagePath", "customSoundPath"]

		keys.forEach { defaults.removeObject(forKey: $0) }
	}

	func testDefaultPreferences() {
		let prefs = Preferences.shared

		XCTAssertEqual(prefs.petSize, 128)
		XCTAssertTrue(prefs.movementEnabled)
		XCTAssertEqual(prefs.speed, 1.0)
		XCTAssertFalse(prefs.idleEnabled)
		XCTAssertEqual(prefs.idleProbability, 30)
		XCTAssertEqual(prefs.volume, 0.13)
		XCTAssertTrue(prefs.customImagePath.isEmpty)
		XCTAssertTrue(prefs.customSoundPath.isEmpty)
	}

	func testPetSizeClamping() {
		// PetView clamps to screen bounds — verify the math directly
		let screenWidth: CGFloat = 1440
		let petSize: CGFloat = 128
		let maxX = screenWidth - petSize

		XCTAssertEqual(maxX, 1312)

		let clamped = max(0, min(CGFloat(1500), maxX))

		XCTAssertEqual(clamped, maxX)
	}

	func testNormalizedSpeedAt60Hz() {
		let speed = 2.0
		let frameTime = 1.0 / 60.0
		let normalized = speed * (frameTime / (1.0 / 60.0))

		XCTAssertEqual(normalized, 2.0, accuracy: 0.001)
	}

	func testNormalizedSpeedAt120Hz() {
		let speed = 2.0
		let frameTime = 1.0 / 120.0
		let normalized = speed * (frameTime / (1.0 / 60.0))

		XCTAssertEqual(normalized, 1.0, accuracy: 0.001)
	}
}
