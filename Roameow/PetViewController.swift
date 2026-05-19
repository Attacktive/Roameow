import AppKit

class PetViewController: NSViewController {
	private var petView: PetView { view as! PetView }

	override func loadView() {
		let screen = NSScreen.main ?? NSScreen.screens[0]
		self.view = PetView(frame: NSRect(origin: .zero, size: screen.frame.size))
	}

	func clampToScreenBounds() { petView.clampToScreenBounds() }
	func pause() { petView.pause() }
	func resume() { petView.resume() }
}
