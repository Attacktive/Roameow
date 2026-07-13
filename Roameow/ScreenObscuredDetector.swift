import AppKit

/// Reports when the display's normal content is hidden by the login window (screen locked) or the screen saver, so overlay movement can pause instead of roaming invisibly.
///
/// Lock and screen saver are watched independently because either can happen without the other: the saver runs unlocked when no password is required, and the screen can lock with no saver at all.
/// These are the standard—if undocumented—`DistributedNotificationCenter` names; they are only delivered to non-sandboxed apps, which Roameow is (`com.apple.security.app-sandbox` is false).
/// A display that actually sleeps needs no handling here: the display link stops on its own once vsync stops, so `PetView` already idles then.
final class ScreenObscuredDetector: NSObject {
	private let onChange: (Bool) -> Void
	private var isLocked = false
	private var isScreenSaverActive = false
	private var lastObscured = false

	init(onChange: @escaping (Bool) -> Void) {
		self.onChange = onChange
	}

	func start() {
		let center = DistributedNotificationCenter.default()
		center.addObserver(self, selector: #selector(screenDidLock), name: .init("com.apple.screenIsLocked"), object: nil)
		center.addObserver(self, selector: #selector(screenDidUnlock), name: .init("com.apple.screenIsUnlocked"), object: nil)
		center.addObserver(self, selector: #selector(screenSaverDidStart), name: .init("com.apple.screensaver.didstart"), object: nil)
		center.addObserver(self, selector: #selector(screenSaverDidStop), name: .init("com.apple.screensaver.didstop"), object: nil)
	}

	@objc func screenDidLock() {
		isLocked = true
		emit()
	}

	@objc func screenDidUnlock() {
		isLocked = false
		emit()
	}

	@objc func screenSaverDidStart() {
		isScreenSaverActive = true
		emit()
	}

	@objc func screenSaverDidStop() {
		isScreenSaverActive = false
		emit()
	}

	/// Collapses the two signals to a single obscured/visible edge, firing only when that edge actually flips so overlapping lock+saver events do not double-pause or prematurely resume.
	private func emit() {
		let obscured = isLocked || isScreenSaverActive
		guard obscured != lastObscured else { return }

		lastObscured = obscured
		onChange(obscured)
	}

	deinit {
		DistributedNotificationCenter.default().removeObserver(self)
	}
}
