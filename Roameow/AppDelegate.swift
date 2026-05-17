import AppKit
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
	private var overlayWindowControllers: [CGDirectDisplayID: OverlayWindowController] = [:]
	private var statusBarController: StatusBarController?
	private var settingsWindowController: SettingsWindowController?
	var updaterController: SPUStandardUpdaterController?

	func applicationDidFinishLaunching(_ notification: Notification) {
		updaterController = SPUStandardUpdaterController(
			startingUpdater: true,
			updaterDelegate: nil,
			userDriverDelegate: nil
		)

		for screen in NSScreen.screens {
			guard let id = displayID(for: screen) else { continue }
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
	}

	@objc private func screenParametersDidChange() {
		let currentScreens = NSScreen.screens
		let currentIDs = Set(currentScreens.compactMap { displayID(for: $0) })
		let existingIDs = Set(overlayWindowControllers.keys)

		for id in existingIDs.subtracting(currentIDs) {
			overlayWindowControllers[id]?.window?.close()
			overlayWindowControllers.removeValue(forKey: id)
		}

		for screen in currentScreens {
			guard let id = displayID(for: screen) else { continue }
			if overlayWindowControllers[id] == nil {
				let controller = OverlayWindowController(screen: screen)
				controller.showWindow(nil)
				overlayWindowControllers[id] = controller
			} else {
				overlayWindowControllers[id]?.handleScreenChange()
			}
		}
	}

	private func displayID(for screen: NSScreen) -> CGDirectDisplayID? {
		screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
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
