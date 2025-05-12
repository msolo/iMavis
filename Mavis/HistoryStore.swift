import SwiftUI

@Observable
class HistoryStore: ObservableObject {
  var history: [Message] = []

  private static func fileURL() -> URL {
    MVFileManager.shared.history
  }

  func load() async throws {
    let task = Task<[Message], Error> {
      let fileURL = Self.fileURL()
      guard let data = try? Data(contentsOf: fileURL) else {
        return []
      }
      let history = try JSONDecoder().decode([Message].self, from: data)
      return history
    }
    let history = try await task.value
    self.history = history
  }

  func save(history: [Message]) async throws {
    let task = Task {
      let data = try JSONEncoder().encode(history)
      let outfile = Self.fileURL()
      try data.write(to: outfile)
    }
    _ = try await task.value
  }
}
