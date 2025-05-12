import AVFoundation
import Foundation

@MainActor
class AudioManager {
  static let shared = AudioManager()

  private var engine: AVAudioEngine
  private var player: AVAudioPlayer?
  private var bufferCache: [String: AVAudioPCMBuffer] = [:]

  private init() {
    engine = AVAudioEngine()
  }

  func loadAudio(file: URL) -> AVAudioPCMBuffer? {
    if let buf = bufferCache[file.absoluteString] {
      return buf
    }
    do {
      let aFile = try AVAudioFile(forReading: file)
      if let buf = AVAudioPCMBuffer(
        pcmFormat: aFile.processingFormat, frameCapacity: AVAudioFrameCount(aFile.length))
      {
        try aFile.read(into: buf)
        bufferCache[file.absoluteString] = buf
        return buf
      }
    } catch {
      let nsError = error as NSError
      print("error loading audio file", nsError.localizedDescription)
    }
    return nil
  }

  func play(file: URL, volume: Float) {
    guard let buf = loadAudio(file: file) else {
      return
    }
    let pn = AVAudioPlayerNode()
    //        Doesn't seem to help, stutters on first playback on iPhone.
    //        pn.prepare(withFrameCount: buf.frameLength)
    engine.attach(pn)
    engine.connect(pn, to: engine.mainMixerNode, format: buf.format)
    do {
      try engine.start()
    } catch {
      let nsError = error as NSError
      print("error starting audio engine", nsError.localizedDescription)
      return
    }
    pn.volume = volume
    pn.scheduleBuffer(buf)
    pn.play()
  }
}

func audioInit() {
  let session = AVAudioSession.sharedInstance()
  do {
    // FIXME: Nothing I've set here manages to get audio from this app to route over facetime.
    // Probably a full on SharePlay activity is required.
    // Set the session so audio plays, even in silent mode.
    try session.setCategory(.playback, mode: .voicePrompt)
  } catch {
    print("Failed to configure audio session: \(error)")
  }
}
