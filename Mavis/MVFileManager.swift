import Foundation
import ZIPFoundation

enum MVConfigFile: String, CaseIterable {
  case phrases = "phrases.txt"
  case pronunciations = "pronunciations.txt"
  case log = "log.jsonl"
  case history = "history.json"
  case soundbites = "soundbites.zip"
}

// A simple string wrapper to show an error message to the user.
struct MVError: LocalizedError {
  var message: String

  var errorDescription: String? {
    return message
  }
}

class MVFileManager {

  static let shared = MVFileManager()

  private var modDateByPath: [String: Double]

  private init() {
    modDateByPath = [:]
  }

  var phrases: URL {
    return try! userFile(MVConfigFile.phrases.rawValue, isPublic: true)
  }

  var pronunciations: URL {
    return try! userFile(MVConfigFile.pronunciations.rawValue, isPublic: true)
  }

  var history: URL {
    return try! userFile(MVConfigFile.history.rawValue, isPublic: false)
  }

  var log: URL {
    return try! userFile(MVConfigFile.log.rawValue, isPublic: false)
  }

  func getFileStore(forUrl url: URL) -> FileStore {
    return FileStore(url: url)
  }

  func readFileDataIfModified(fileURL: URL) throws -> String? {
    do {
      let fm = FileManager.default
      let path = fileURL.path
      let attrs = try fm.attributesOfItem(atPath: path)
      if let modDate = attrs[.modificationDate] as? Date {
        if modDate.timeIntervalSince1970 == modDateByPath[path] {
          return nil
        }
        let txt = try readFile(fileURL: fileURL)
        modDateByPath[path] = modDate.timeIntervalSince1970
        return txt
      }
      return nil
    } catch CocoaError.fileReadNoSuchFile {
      return nil
    }
  }

  func readFileDataAsStringArrayIfModified(fileURL: URL) throws -> [String]? {
    guard let txt = try readFileDataIfModified(fileURL: fileURL) else {
      return nil
    }
    var sl: [String] = []
    for s in txt.components(separatedBy: CharacterSet(charactersIn: "\n")) {
      if s.count > 0 {
        sl.append(s)
      }
    }
    return sl
  }

  func readDir(dirURL: URL) throws -> [String]? {
    let fm = FileManager.default
    do {
      let attrs = try fm.attributesOfItem(atPath: dirURL.path)
      if let modDate = attrs[FileAttributeKey.modificationDate] as? Date {
        if modDateByPath[dirURL.path] == modDate.timeIntervalSince1970 {
          return nil
        }

        let dirList = try fm.contentsOfDirectory(atPath: dirURL.path)
        modDateByPath[dirURL.path] = modDate.timeIntervalSince1970
        return dirList
      }
    } catch CocoaError.fileReadNoSuchFile {
      return nil
    }
    return nil
  }

  // If we drop a file someplace, copy it into our sandbox.
  func copyFileIntoDocs(fileURL: URL) throws {
    let fm = FileManager.default
    let fname = fileURL.lastPathComponent
    if !MVConfigFile.allCases.contains(where: {
      $0.rawValue == fname
    }) {
      throw MVError(
        message:
          "Unrecognized file name \"\(fname)\". Please consult the documentation for a set of recognized file names."
      )
    }

    // Without this line, we get a permission error.
    guard fileURL.startAccessingSecurityScopedResource() else {
      return
    }

    if fname.hasSuffix(".zip") {
      let dir = String(fname.prefix(fname.count - ".zip".count))
      let dirURL = try userFile(dir, isPublic: true)
      try fm.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
      try fm.unzipItem(at: fileURL, to: dirURL, pathEncoding: .utf8)
      return
    }
    let newPath = try userFile(fname, isPublic: true)
    try fm.copyItem(at: fileURL, to: newPath)
  }
}

func userFile(_ name: String, isPublic: Bool) throws -> URL {
  let fileManager = FileManager.default
  var searchDir = FileManager.SearchPathDirectory.applicationSupportDirectory
  if isPublic {
    searchDir = FileManager.SearchPathDirectory.documentDirectory
  }
  guard let dir = fileManager.urls(for: searchDir, in: .userDomainMask).first else {
    throw MVError(message: "directory not found: \(searchDir)")
  }
  return dir.appending(component: name)
}

func readFile(fileURL: URL) throws -> String {
  let fileContents = try String(contentsOf: fileURL, encoding: .utf8)
  return fileContents
}
