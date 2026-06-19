import Combine
import Foundation

class Preferences: ObservableObject {
	static let shared = Preferences()

	let objectWillChange = ObservableObjectPublisher()
	private let defaults: UserDefaults

	init(defaults: UserDefaults = .standard) {
		self.defaults = defaults
	}

	var petSize: Double { get { number("petSize", 128) } set { store(newValue, "petSize") } }
	var movementEnabled: Bool { get { flag("movementEnabled", true) } set { store(newValue, "movementEnabled") } }
	var speed: Double { get { number("speed", 1.0) } set { store(newValue, "speed") } }
	var idleEnabled: Bool { get { flag("idleEnabled", false) } set { store(newValue, "idleEnabled") } }
	var idleProbability: Double { get { number("idleProbability", 30) } set { store(newValue, "idleProbability") } }
	var volume: Double { get { number("volume", 0.13) } set { store(newValue, "volume") } }
	var customImagePath: String { get { defaults.string(forKey: "customImagePath") ?? "" } set { store(newValue, "customImagePath") } }
	var customSoundPath: String { get { defaults.string(forKey: "customSoundPath") ?? "" } set { store(newValue, "customSoundPath") } }

	private func number(_ key: String, _ fallback: Double) -> Double {
		defaults.object(forKey: key) == nil ? fallback : defaults.double(forKey: key)
	}

	private func flag(_ key: String, _ fallback: Bool) -> Bool {
		defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
	}

	private func store<T>(_ value: T, _ key: String) {
		objectWillChange.send()
		defaults.set(value, forKey: key)
	}

	var resolvedImageURL: URL? {
		if !customImagePath.isEmpty, FileManager.default.fileExists(atPath: customImagePath) {
			return URL(fileURLWithPath: customImagePath)
		}

		return Bundle.main.url(forResource: "Happy Cat", withExtension: "gif")
	}

	var resolvedSoundURL: URL? {
		if !customSoundPath.isEmpty, FileManager.default.fileExists(atPath: customSoundPath) {
			return URL(fileURLWithPath: customSoundPath)
		}

		return Bundle.main.url(forResource: "meow", withExtension: "mp3")
	}
}
