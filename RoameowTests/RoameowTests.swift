import XCTest
import AppKit
@testable import Roameow

final class RoameowTests: XCTestCase {
	func testDefaultPreferences() {
		let suite = UserDefaults(suiteName: #function)!
		suite.removePersistentDomain(forName: #function)
		let prefs = Preferences(defaults: suite)

		XCTAssertEqual(prefs.petSize, 128)
		XCTAssertTrue(prefs.movementEnabled)
		XCTAssertEqual(prefs.speed, 1.0)
		XCTAssertFalse(prefs.idleEnabled)
		XCTAssertEqual(prefs.idleProbability, 30)
		XCTAssertEqual(prefs.volume, 0.13)
		XCTAssertTrue(prefs.customImagePath.isEmpty)
		XCTAssertTrue(prefs.customSoundPath.isEmpty)
	}

	func testPreviewImageCacheReusesDecodedImage() throws {
		let url = URL(fileURLWithPath: NSTemporaryDirectory())
			.appendingPathComponent("roameow-preview-\(ProcessInfo.processInfo.globallyUniqueString).png")

		defer { try? FileManager.default.removeItem(at: url) }

		let rep = try XCTUnwrap(
			NSBitmapImageRep(
				bitmapDataPlanes: nil,
				pixelsWide: 4,
				pixelsHigh: 4,
				bitsPerSample: 8,
				samplesPerPixel: 4,
				hasAlpha: true,
				isPlanar: false,
				colorSpaceName: .deviceRGB,
				bytesPerRow: 0,
				bitsPerPixel: 0
			)
		)

		try XCTUnwrap(rep.representation(using: .png, properties: [:])).write(to: url)

		let first = try XCTUnwrap(PreviewImageCache.image(for: url))
		let second = PreviewImageCache.image(for: url)

		XCTAssertTrue(first === second, "decoded preview should be cached and reused")
		XCTAssertNil(PreviewImageCache.image(for: nil))
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

	func testNormalizedSpeedAtArbitraryRefresh() {
		// A display link feeds real per-frame deltas, not just clean 60/120 Hz, so speed must scale linearly with frame time at any refresh rate.
		let speed = 2.0
		let frameTime = 1.0 / 90.0
		let normalized = speed * (frameTime / (1.0 / 60.0))

		XCTAssertEqual(normalized, 2.0 * 60.0 / 90.0, accuracy: 0.001)
	}

	// MARK: - FullscreenDetector.coveredDisplays

	private let displayA = DisplayBounds(id: 1, bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080))
	private let displayB = DisplayBounds(id: 2, bounds: CGRect(x: 1920, y: 0, width: 1920, height: 1080))

	func testFullscreenWindowFlagsDisplay() {
		let window = WindowInfo(bounds: displayA.bounds, pid: 99, layer: 0)
		let covered = FullscreenDetector.coveredDisplays(windows: [window], displays: [displayA], ownPID: 42)

		XCTAssertEqual(covered, [1])
	}

	func testOwnOverlayDoesNotFlagDisplay() {
		let window = WindowInfo(bounds: displayA.bounds, pid: 42, layer: 0)
		let covered = FullscreenDetector.coveredDisplays(windows: [window], displays: [displayA], ownPID: 42)

		XCTAssertTrue(covered.isEmpty)
	}

	func testMaximizedButSmallerWindowDoesNotFlagDisplay() {
		let smaller = CGRect(x: 0, y: 0, width: 1920, height: 1040)
		let window = WindowInfo(bounds: smaller, pid: 99, layer: 0)
		let covered = FullscreenDetector.coveredDisplays(windows: [window], displays: [displayA], ownPID: 42)

		XCTAssertTrue(covered.isEmpty)
	}

	func testNonZeroLayerWindowDoesNotFlagDisplay() {
		let window = WindowInfo(bounds: displayA.bounds, pid: 99, layer: 25)
		let covered = FullscreenDetector.coveredDisplays(windows: [window], displays: [displayA], ownPID: 42)

		XCTAssertTrue(covered.isEmpty)
	}

	func testFullscreenOnOneDisplayOnlyFlagsThatDisplay() {
		let window = WindowInfo(bounds: displayA.bounds, pid: 99, layer: 0)
		let covered = FullscreenDetector.coveredDisplays(
			windows: [window],
			displays: [displayA, displayB],
			ownPID: 42
		)

		XCTAssertEqual(covered, [1])
	}

	func testNoWindowsYieldsEmptySet() {
		let covered = FullscreenDetector.coveredDisplays(
			windows: [],
			displays: [displayA, displayB],
			ownPID: 42
		)

		XCTAssertTrue(covered.isEmpty)
	}
}
