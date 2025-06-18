import SwiftUI

@Observable
class FileStore: ObservableObject, Equatable, Hashable {
  static func == (lhs: FileStore, rhs: FileStore) -> Bool {
    lhs.url == rhs.url && lhs.contents == rhs.contents
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(url)
    hasher.combine(contents)
  }

  var url: URL
  var contents: String = ""

  init(url: URL) {
    self.url = url
  }

  var name: String {
    url.lastPathComponent
  }

  func load() {
    do {
      contents = try readFile(fileURL: url)
    } catch {
      print("Failed loading file:", url, error)
    }
  }

  func save() {
    do {
      try contents.write(to: url, atomically: true, encoding: .utf8)
    } catch {
      print("Failed saving file:", url, error)
    }
  }
}
