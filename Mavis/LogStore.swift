import SwiftUI

class LogStore {
  public static let shared = LogStore()

  private static func fileURL() -> URL {
    MVFileManager.shared.log
  }

  private func saveRecord(rec: [String: Any?]) throws {
    // Attempt to convert the dictionary to JSON data
    // Use JSONSerialization because is handles Dictionary<String,Any?>
    // whereas JSONEncoded requires type system gymnastics that yield no value.
    //
    // Guarantee stable order of records. Realistically, this is mostly
    // aesthetic for the reader.
    guard let data = try? JSONSerialization.data(withJSONObject: rec, options: .sortedKeys) else {
      print("Failed to serialize json for logging")
      return
    }

    let path = Self.fileURL().path
    let fm = FileManager.default
    if !fm.fileExists(atPath: path) {
      fm.createFile(atPath: path, contents: nil)
    }
    // Open file for appending
    guard let fh = FileHandle(forWritingAtPath: path) else {
      print("Failed to open file for writing: \(path)")
      return
    }

    fh.seekToEndOfFile()
    fh.write(data)
    fh.write("\n".data(using: .utf8)!)
    fh.closeFile()
  }

  func log(
    string s: String, withInputKeystrokes keystrokes: String, withAnnotations dict: [String: Any?]?
  ) {
    guard Prefs.shared.logChatHistory else {
      return
    }
    let rfc3339 = DateFormatter()
    rfc3339.locale = Locale(identifier: "en_US_POSIX")
    rfc3339.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    rfc3339.timeZone = TimeZone.gmt
    let ts = rfc3339.string(from: Date.now)

    var rec: [String: Any?] = [
      "text": s,
      "keystrokes": keystrokes,
      "timestamp": ts,
    ]

    if let d = dict {
      d.forEach { (key, value) in rec[key] = value }
    }

    // Fire this off in the background. If it fails, it's only logging. Not critical.
    Task {
      do {
        try self.saveRecord(rec: rec)
      } catch {
        print(error)
      }
    }
  }
}
