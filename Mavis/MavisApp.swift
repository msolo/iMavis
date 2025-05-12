import SwiftUI

// FIXME: preloading audio didn't help stuttering on iPhone.
//@MainActor func preload() {
//    _ = AudioManager.shared.loadAudio(file:keyClickSoundFile)
//    _ = AudioManager.shared.loadAudio(file:bellSoundFile)
//    _ = AudioManager.shared.loadAudio(file:loudBellSoundFile)
//    print("preloaded audio")
//}

@main
struct MavisApp: App {
  @StateObject private var historyStore = HistoryStore()
  @StateObject private var completer = CompletionManager.shared

  init() {
    audioInit()
    ZeroConfController.shared.discover(serviceType: "_mavis-corrector._tcp")
    //        preload()
  }

  func save() {
    Task {
      do {
        try await historyStore.save(history: historyStore.history)
      } catch {
        print("Failed to store history: \(error)")
      }
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView(
        messages: $historyStore.history, saveAction: save, completions: $completer.completions
      )
      .task {
        SpeechManager.shared.auth()
        do {
          try await historyStore.load()
        } catch {
          print("Failed to load history: \(error)")
        }
      }
    }
  }
}
