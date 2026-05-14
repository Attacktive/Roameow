import AppKit
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
	private var overlayWindowController: OverlayWindowController?
	private var statusBarController: StatusBarController?
	private var settingsWindowController: SettingsWindowController?
	var updaterController: SPUStandardUpdaterController?

	func applicationDidFinishLaunching(_ notification: Notification) {
		updaterController = SPUStandardUpdaterController(
			startingUpdater: true,
			updaterDelegate: nil,
			userDriverDelegate: nil
		)

		overlayWindowController = OverlayWindowController()
		overlayWindowController?.showWindow(nil)

		statusBarController = StatusBarController(appDelegate: self)

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(screenParametersDidChange),
			name: NSApplication.didChangeScreenParametersNotification,
			object: nil
		)
	}

	@objc private func screenParametersDidChange() {
		overlayWindowController?.handleScreenChange()
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
