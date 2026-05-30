import AppKit
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
	var updaterController: SPUStandardUpdaterController?

	private var overlayWindowControllers: [CGDirectDisplayID: OverlayWindowController] = [:]
	private var statusBarController: StatusBarController?
	private var settingsWindowController: SettingsWindowController?
	private var fullscreenDetector: FullscreenDetector?

	func applicationDidFinishLaunching(_ notification: Notification) {
		updaterController = SPUStandardUpdaterController(
			startingUpdater: true,
			updaterDelegate: nil,
			userDriverDelegate: nil
		)

		for screen in NSScreen.screens {
			guard let id = screen.displayID else { continue }
			let controller = OverlayWindowController(screen: screen)
			controller.showWindow(nil)
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

			for (id, controller) in self.overlayWindowControllers {
				controller.setActive(!covered.contains(id))
			}
		}

		fullscreenDetector = detector
		detector.start()
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
				controller.showWindow(nil)
				overlayWindowControllers[id] = controller
			} else {
				overlayWindowControllers[id]?.handleScreenChange(screen: screen)
			}
		}

		fullscreenDetector?.evaluate()
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
}
