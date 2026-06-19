import SwiftUI
import AppKit
import AVFoundation
import ServiceManagement

private struct AnimatedImageView: NSViewRepresentable {
	let image: NSImage?

	func makeNSView(context: Context) -> NSImageView {
		let view = NSImageView()
		view.animates = true
		view.imageScaling = .scaleProportionallyUpOrDown
		return view
	}

	func updateNSView(_ view: NSImageView, context: Context) {
		if view.image !== image {
			view.image = image
		}
	}
}

// MARK: - Preview Image Cache

enum PreviewImageCache {
	private static var images: [URL: NSImage] = [:]

	static func image(for url: URL?) -> NSImage? {
		guard let url else { return nil }
		if let cached = images[url] {
			return cached
		}

		let image = NSImage(contentsOf: url)
		images[url] = image
		return image
	}
}

struct SettingsView: View {
	@State private var selectedTab = 0

	var body: some View {
		VStack(spacing: 0) {
			Picker("", selection: $selectedTab) {
				Label("Image", systemImage: "photo").tag(0)
				Label("Movement", systemImage: "figure.walk").tag(1)
				Label("Sound", systemImage: "speaker.wave.2").tag(2)
				Label("General", systemImage: "gearshape").tag(3)
			}
			.pickerStyle(.segmented)
			.padding()

			Divider()

			Group {
				switch selectedTab {
				case 0: ImageTab()
				case 1: MovementTab()
				case 2: SoundTab()
				case 3: GeneralTab()
				default: EmptyView()
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
		.frame(width: 400, height: 360)
	}
}

// MARK: - Image Tab

private struct ImageTab: View {
	@ObservedObject private var prefs = Preferences.shared

	var body: some View {
		VStack(spacing: 12) {
			AnimatedImageView(image: previewImage)
				.frame(width: 100, height: 100)
				.padding(.top, 12)

			VStack(alignment: .leading, spacing: 12) {
				VStack(alignment: .leading, spacing: 4) {
					HStack {
						Text("Size: \(Int(prefs.petSize)) pt")
						Spacer()
						Button("Reset") { prefs.petSize = 128 }
							.buttonStyle(.plain)
							.foregroundColor(.accentColor)
							.font(.caption)
					}
					Slider(value: $prefs.petSize, in: 32...512, step: 32)
				}

				VStack(alignment: .leading, spacing: 6) {
					Text("Custom image")
						.font(.headline)
					HStack {
						Text(imageLabel)
							.lineLimit(1)
							.truncationMode(.middle)
							.foregroundColor(.secondary)
						Spacer()
						Button("Choose…") { pickImage() }
						if !prefs.customImagePath.isEmpty {
							Button("Reset") { prefs.customImagePath = "" }
						}
					}
				}
			}
			.padding(.horizontal)

			Spacer()
		}
	}

	private var previewImage: NSImage? {
		PreviewImageCache.image(for: prefs.resolvedImageURL)
	}

	private var imageLabel: String {
		prefs.customImagePath.isEmpty
			? "Happy Cat.gif"
			: URL(fileURLWithPath: prefs.customImagePath).lastPathComponent
	}

	private func pickImage() {
		let panel = NSOpenPanel()
		panel.allowedContentTypes = [.image]
		panel.allowsMultipleSelection = false
		guard
			panel.runModal() == .OK,
			let url = panel.url
		else {
			return
		}

		prefs.customImagePath = url.path
	}
}

// MARK: - Movement Tab

private struct MovementTab: View {
	@ObservedObject private var prefs = Preferences.shared

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Toggle("Enable movement", isOn: $prefs.movementEnabled)

			VStack(alignment: .leading, spacing: 4) {
				Text("Speed: \(String(format: "%.1f", prefs.speed))×")
				Slider(value: $prefs.speed, in: 0.5...10.0)
			}
			.disabled(!prefs.movementEnabled)

			Toggle("Random idle", isOn: $prefs.idleEnabled)
				.disabled(!prefs.movementEnabled)

			if prefs.idleEnabled && prefs.movementEnabled {
				Stepper(
					"Idle probability: \(Int(prefs.idleProbability))%",
					value: $prefs.idleProbability,
					in: 1...100,
					step: 1
				)
			}

			Spacer()
		}
		.padding()
	}
}

// MARK: - Sound Tab

private struct SoundTab: View {
	@ObservedObject private var prefs = Preferences.shared
	@State private var testPlayer: AVAudioPlayer?

	var body: some View {
		Form {
			VStack(alignment: .leading, spacing: 4) {
				Text("Volume: \(Int(prefs.volume * 100))%")
				Slider(value: $prefs.volume, in: 0...1)
			}
			.padding(.vertical, 4)

			VStack(alignment: .leading, spacing: 6) {
				Text("Custom sound")
					.font(.headline)
				HStack {
					Text(soundLabel)
						.lineLimit(1)
						.truncationMode(.middle)
						.foregroundColor(.secondary)
					Spacer()
					Button("Choose…") { pickSound() }
					if !prefs.customSoundPath.isEmpty {
						Button("Reset") { prefs.customSoundPath = "" }
					}
				}
			}
			.padding(.vertical, 4)

			Button("Test sound") { playTest() }
		}
		.padding()
	}

	private var soundLabel: String {
		prefs.customSoundPath.isEmpty
			? "Built-in meow"
			: URL(fileURLWithPath: prefs.customSoundPath).lastPathComponent
	}

	private func pickSound() {
		let panel = NSOpenPanel()
		panel.allowedContentTypes = [.audio]
		panel.allowsMultipleSelection = false
		guard
			panel.runModal() == .OK,
			let url = panel.url
		else {
			return
		}

		prefs.customSoundPath = url.path
	}

	private func playTest() {
		guard let url = prefs.resolvedSoundURL else { return }

		testPlayer = try? AVAudioPlayer(contentsOf: url)
		testPlayer?.volume = Float(prefs.volume)
		testPlayer?.play()
	}
}

// MARK: - General Tab

private struct GeneralTab: View {
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Toggle(
				"Launch at login",
				isOn: Binding(
					get: { LaunchAtLogin.isEnabled },
					set: { LaunchAtLogin.isEnabled = $0 }
				)
			)
			.disabled(!LaunchAtLogin.isAvailable)

			Spacer()
		}
		.padding()
	}
}

// MARK: - Launch at Login

enum LaunchAtLogin {
	static var isAvailable: Bool {
		if #available(macOS 13.0, *) {
			return true
		}

		return false
	}

	static var isEnabled: Bool {
		get {
			guard #available(macOS 13.0, *) else { return false }

			let status = SMAppService.mainApp.status

			return status == .enabled || status == .requiresApproval
		}
		set {
			guard #available(macOS 13.0, *) else { return }

			do {
				if newValue {
					try SMAppService.mainApp.register()
				} else {
					try SMAppService.mainApp.unregister()
				}
			} catch {
				NSLog("Roameow: could not update Launch at Login — \(error.localizedDescription)")
			}
		}
	}
}
