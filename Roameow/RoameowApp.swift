import SwiftUI

@main
struct RoameowApp: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	var body: some Scene {
		Settings {
			EmptyView()
		}
	}
}
