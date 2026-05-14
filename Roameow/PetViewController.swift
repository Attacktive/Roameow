import AppKit

class PetViewController: NSViewController {
	override func loadView() {
		let screen = NSScreen.main ?? NSScreen.screens[0]
		self.view = PetView(frame: NSRect(origin: .zero, size: screen.frame.size))
	}

	func clampToScreenBounds() {
		(view as? PetView)?.clampToScreenBounds()
	}
}
