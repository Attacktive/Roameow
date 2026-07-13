import AppKit
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate {
	var updaterController: SPUStandardUpdaterController?

	private var overlayWindowControllers: [CGDirectDisplayID: OverlayWindowController] = [:]
	private var statusBarController: StatusBarController?
	private var settingsWindowController: SettingsWindowController?
	private var fullscreenDetector: FullscreenDetector?
	private var screenObscuredDetector: ScreenObscuredDetector?
	private var coveredDisplays: Set<CGDirectDisplayID> = []
	private var screenObscured = false

	func applicationDidFinishLaunching(_ notification: Notification) {
		updaterController = SPUStandardUpdaterController(
			startingUpdater: true,
			updaterDelegate: self,
			userDriverDelegate: nil
		)

		for screen in NSScreen.screens {
			guard let id = screen.displayID else { continue }

			let controller = OverlayWindowController(screen: screen)
			controller.show()
			overlayWindowControllers[id] = controller
		}

		statusBarController = StatusBarController(appDelegate: self)

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(screenParametersDidChange),
			name: NSApplication.didChangeScreenParametersNotification,
			object: nil
		)

		let detector = FullscreenDetector { [weak self] covered in
			guard let self else { return }

			self.coveredDisplays = covered
			self.applyOverlayActiveStates()
		}

		fullscreenDetector = detector
		detector.start()

		let obscuredDetector = ScreenObscuredDetector { [weak self] obscured in
			guard let self else { return }

			self.screenObscured = obscured
			self.applyOverlayActiveStates()
		}

		screenObscuredDetector = obscuredDetector
		obscuredDetector.start()
	}

	/// Resolves each overlay's active state from both pause sources: a per-display fullscreen cover and the system-wide lock/screen-saver obscuring.
	private func applyOverlayActiveStates() {
		for (id, controller) in overlayWindowControllers {
			controller.setActive(!screenObscured && !coveredDisplays.contains(id))
		}
	}

	@objc private func screenParametersDidChange() {
		let currentScreens = NSScreen.screens
		let currentIDs = Set(currentScreens.compactMap { $0.displayID })
		let existingIDs = Set(overlayWindowControllers.keys)

		for id in existingIDs.subtracting(currentIDs) {
			overlayWindowControllers[id]?.window?.close()
			overlayWindowControllers.removeValue(forKey: id)
		}

		for screen in currentScreens {
			guard let id = screen.displayID else { continue }

			if overlayWindowControllers[id] == nil {
				let controller = OverlayWindowController(screen: screen)
				controller.show()
				overlayWindowControllers[id] = controller
			} else {
				overlayWindowControllers[id]?.handleScreenChange(screen: screen)
			}
		}

		fullscreenDetector?.evaluate()
		applyOverlayActiveStates()
	}

	func showSettings() {
		if settingsWindowController == nil {
			settingsWindowController = SettingsWindowController()
		}

		settingsWindowController?.showWindow(nil)
		settingsWindowController?.window?.makeKeyAndOrderFront(nil)
		NSApp.activate(ignoringOtherApps: true)
	}

	func checkForUpdates() {
		updaterController?.checkForUpdates(nil)
	}

	// MARK: - SPUUpdaterDelegate

	/// Installs a silently-downloaded automatic update immediately instead of letting Sparkle defer it to app quit.
	///
	/// Roameow is a menu-bar agent that users basically never quit, so Sparkle's default "install on quit" leaves a background-downloaded update staged forever: when no delegate handles this callback, the automatic driver aborts and waits for a termination that never comes (see SPUAutomaticUpdateDriver).
	/// Invoking the block and returning true tells Sparkle to install and relaunch right away, which is what makes automatic updates actually land on a background app.
	func updater(
		_ updater: SPUUpdater,
		willInstallUpdateOnQuit item: SUAppcastItem,
		immediateInstallationBlock immediateInstallHandler: @escaping () -> Void
	) -> Bool {
		immediateInstallHandler()
		return true
	}
}
