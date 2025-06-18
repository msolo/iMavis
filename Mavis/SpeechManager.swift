import AVFoundation
import CallKit
import Foundation

final class SpeechManager {
  static let shared = SpeechManager()

  private let synth: AVSpeechSynthesizer
  private var _normalizedSoundbiteMap: [String: URL] = [:]
  private var _soundbites: [String] = []
  private let callObserver = CallObserver()

  private init() {
    synth = AVSpeechSynthesizer()
    synth.mixToTelephonyUplink = true
  }

  func auth() {
    if AVSpeechSynthesizer.personalVoiceAuthorizationStatus != .authorized {
      print("request personal voice", AVSpeechSynthesizer.personalVoiceAuthorizationStatus)
      AVSpeechSynthesizer.requestPersonalVoiceAuthorization { status in
        print("personalVoice Status", status)
      }
    }
  }

  func getVoices() -> [AVSpeechSynthesisVoice] {
    var vl: [AVSpeechSynthesisVoice] = []
    for v in AVSpeechSynthesisVoice.speechVoices() {
      if v.voiceTraits == AVSpeechSynthesisVoice.Traits.isPersonalVoice {
        vl.append(v)
      } else if v.language.hasPrefix("en") {
        // Try to prefer high quality voices.
        if v.quality != AVSpeechSynthesisVoiceQuality.default {
          vl.append(v)
        }
      }
    }
    if vl.isEmpty {
      // Fall back to this first available voice in our language.
      for v in AVSpeechSynthesisVoice.speechVoices() {
        if v.language.hasPrefix("en") {
          vl.append(v)
          break
        }
      }
    }
    return vl
  }

  var voice: AVSpeechSynthesisVoice {
    return defaultVoice()
  }

  private func defaultVoice() -> AVSpeechSynthesisVoice {
    if let vid = UserDefaults.standard.string(forKey: "speechVoiceIdentifier") {
      if let voice = AVSpeechSynthesisVoice.init(identifier: vid) {
        return voice
      }
    }

    let voices = getVoices()
    for v in voices {
      // If we have a personal voice, use that.
      if v.voiceTraits == AVSpeechSynthesisVoice.Traits.isPersonalVoice {
        return v
      }
    }
    // Otherwise, we just pick the last at random.
    return voices.last!
  }

  @MainActor func say(
    text: String,
    voice: AVSpeechSynthesisVoice,
    rate: Float,
    pitch: Float,
    volume: Float
  ) {

    if Prefs.shared.enableSoundbites && !callObserver.hasActiveCall {
      if let furl = matchingSoundbite(text: text) {
        let vol = Prefs.shared.soundbiteVolume
        print("play soundbite: \(furl) volume: \(vol)")
        AudioManager.shared.play(file: furl, volume: Float(vol))
        return
      }
    }

    // Do a little preprocessing.
    var t2 = fixSynthBugs(text: text)
    t2 = fixPronunciations(text: t2)

    var utt = AVSpeechUtterance(string: t2)
    if t2.hasPrefix("<") {
      utt = AVSpeechUtterance(ssmlRepresentation: t2) ?? utt
    }

    if synth.isSpeaking {
      synth.stopSpeaking(at: AVSpeechBoundary.immediate)
      // Give a small gap so people can notice!
      utt.preUtteranceDelay = 0.300
    }

    utt.rate = rate
    utt.pitchMultiplier = pitch
    utt.voice = voice
    utt.volume = volume
    synth.speak(utt)
  }

  func stop() {
    if synth.isSpeaking {
      synth.stopSpeaking(at: AVSpeechBoundary.immediate)
    }
  }

  var pronunciationMap: [String: String] = [:]

  func fixPronunciations(text: String) -> String {
    do {
      if let lines = try MVFileManager.shared.readFileDataAsStringArrayIfModified(
        fileURL: MVFileManager.shared.pronunciations)
      {
        var pronunciationDict: [String: String] = [:]

        for line in lines {
          let fields = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
          if fields.count == 2 {
            let key = fields[0].lowercased()
            let value = fields[1]
            pronunciationDict[key] = value
          }
        }
        self.pronunciationMap = pronunciationDict
      }
    } catch CocoaError.fileReadNoSuchFile {
      // Not everyone will have pronunciations.
    } catch {
      print("Failed loading pronunciations: \(error)")
    }
    // Tokenize the input text and apply pronunciation fixes
    var tokens = CompletionManager.tokenizeText(text: text)

    for i in 0..<tokens.count {
      let token = tokens[i].lowercased()
      if let correctedToken = pronunciationMap[token] {
        tokens[i] = correctedToken
      }
    }

    // Join the tokens into a single string and return
    return tokens.joined()
  }

  private func normalizeBite(_ bite: String) -> String {
    // dreaded "smart" apostrophe.
    let s = bite.replacingOccurrences(of: "’", with: "'")
    // Remove trailing period, but retain ! and ? in case they indicate some exitement.
    return s.lowercased().trimmingCharacters(
      in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: ".")))
  }

  private func reloadSoundbites() {
    do {
      let validExtensions = ["m4a", "wav"]
      let dir = try userFile("soundbites", isPublic: true)

      guard let files = try MVFileManager.shared.readDirIfModified(dirURL: dir) else {
        return
      }
      var bites: [String] = []
      var normBiteURLMap: [String: URL] = [:]
      for f in files {
        let fname = f as NSString
        if !validExtensions.contains(fname.pathExtension) {
          continue
        }
        let bite = fname.deletingPathExtension
        let normBite = normalizeBite(bite)
        let fu = dir.appending(path: f)
        bites.append(bite)
        normBiteURLMap[normBite] = fu
      }
      bites.sort()
      _soundbites = bites
      _normalizedSoundbiteMap = normBiteURLMap
    } catch {
      print("reloadSoundbites failed: \(error)")
    }
  }

  private var normalizedSoundbiteMap: [String: URL] {
    reloadSoundbites()
    return _normalizedSoundbiteMap
  }

  var soundbites: [String] {
    reloadSoundbites()
    return _soundbites
  }

  func matchingSoundbite(text: String) -> URL? {
    return normalizedSoundbiteMap[normalizeBite(text)]
  }
}

func fixSynthBugs(text: String) -> String {
  let slash = CharacterSet(charactersIn: "\\")

  // A trailing backslash causes the string to not be uttered. I can't imagine what this is for.
  return text.trimmingCharacters(in: CharacterSet.whitespaces).trimmingCharacters(in: slash)
}

class CallObserver: NSObject, CXCallObserverDelegate {
  var hasActiveCall = false
  let callObserver = CXCallObserver()

  override init() {
    super.init()
    self.callObserver.setDelegate(self, queue: DispatchQueue.main)
  }

  func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
    // This method is called whenever a call changes its state.
    // These represent past state transitions, so it's possible for both
    // hasEnded and hasConnected to be true on the same call.
    if call.hasEnded {
      hasActiveCall = false
      print("Call hasEnded")
    } else if call.hasConnected {
      print("Call hasConnected")
      hasActiveCall = true
    }
  }
}
