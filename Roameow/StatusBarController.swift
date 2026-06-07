import AppKit

class StatusBarController: NSObject {
	private let statusItem: NSStatusItem
	private weak var appDelegate: AppDelegate?

	init(appDelegate: AppDelegate) {
		self.appDelegate = appDelegate
		statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
		super.init()
		setupButton()
		setupMenu()
	}

	private func setupButton() {
		guard let button = statusItem.button else { return }

		if let url = Bundle.main.url(forResource: "menubar-icon", withExtension: "png"), let image = NSImage(contentsOf: url) {
			image.size = NSSize(width: 18, height: 18)
			button.image = image
		}
	}

	private func setupMenu() {
		let menu = NSMenu()

		let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
		settingsItem.target = self
		menu.addItem(settingsItem)

		let updatesItem = NSMenuItem(title: "Check for Updates…", action: #selector(checkUpdates), keyEquivalent: "")
		updatesItem.target = self
		menu.addItem(updatesItem)

		menu.addItem(.separator())

		menu.addItem(NSMenuItem(title: "Quit Roameow", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

		statusItem.menu = menu
	}

	@objc private func openSettings() {
		appDelegate?.showSettings()
	}

	@objc private func checkUpdates() {
		appDelegate?.checkForUpdates()
	}
}
