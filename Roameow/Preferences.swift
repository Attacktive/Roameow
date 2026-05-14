import SwiftUI

class Preferences: ObservableObject {
	static let shared = Preferences()
	private init() {}

	@AppStorage("petSize") var petSize: Double = 128
	@AppStorage("movementEnabled") var movementEnabled: Bool = true
	@AppStorage("speed") var speed: Double = 1.0
	@AppStorage("idleEnabled") var idleEnabled: Bool = false
	@AppStorage("idleProbability") var idleProbability: Double = 30
	@AppStorage("volume") var volume: Double = 0.13
	@AppStorage("customImagePath") var customImagePath: String = ""
	@AppStorage("customSoundPath") var customSoundPath: String = ""
}
