import Combine
import CoreData
import SwiftUI

struct Message: Hashable, Identifiable, Codable {
  var id: Int
  var message: String
}

var defaultAttrs: [NSAttributedString.Key: Any] = [:]

let MavisAttrKey = NSAttributedString.Key(rawValue: "Mavis")
let MavisAttrSpoken = "spoken"

let commonAbbreviations = [
  "a.m", "ave", "blvd", "capt", "co", "col", "corp", "dr", "e.g", "est", "etc",
  "gen", "i.e", "inc", "jr", "lt", "ltd", "maj", "mr", "mrs", "ms", "mt",
  "no", "p.m", "prof", "rd", "rev", "sgt", "sr", "st", "vol", "vs",
]

let keyClickSoundFile = Bundle.main.url(
  forResource: "Tock", withExtension: ".caf", subdirectory: "Sounds")!
let boopSoundFile = Bundle.main.url(
  forResource: "Boop", withExtension: ".caf", subdirectory: "Sounds")!
let bellSoundFile = Bundle.main.url(
  forResource: "Bell", withExtension: ".m4a", subdirectory: "Sounds")!
let loudBellSoundFile = Bundle.main.url(
  forResource: "Reception Bell", withExtension: ".m4a", subdirectory: "Sounds")!

struct _KeyPress: Equatable {
  var key: KeyEquivalent
  var characters: String
  var modifiers: EventModifiers
  var phase: KeyPress.Phases
  var time: Date

  init(characters: String) {
    self.characters = characters
    if characters == "\n" {
      // CR+LF lives on in 2024.
      key = KeyEquivalent.return
    } else if characters == "" {
      key = KeyEquivalent.delete
    } else {
      key = KeyEquivalent(Character(characters))
    }
    modifiers = EventModifiers()
    phase = KeyPress.Phases.down
    time = Date.now
  }

  init(evt: KeyPress) {
    key = evt.key
    characters = evt.characters
    modifiers = evt.modifiers
    phase = evt.phase
    time = Date.now
  }
}

struct ContentView: View {
  enum FocusedField: Hashable {
    case speechText
    case none
  }

  @Preference(\.noisyTyping) private var noisyTyping
  @Preference(\.logChatHistory) private var logChatHistory
  @Preference(\.speakSentencesAutomatically) private var speakSentencesAutomatically
  @Preference(\.ignoreUselessKeys) private var ignoreUselessKeys
  @Preference(\.disableScreenLock) private var disableScreenLock
  @Preference(\.enableCorrectorService) private var enableCorrectorService
  @Preference(\.showCorrectionsAutomatically) private var showCorrectionsAutomatically

  @State var speechText: NSAttributedString = NSAttributedString(string: "")
  @State var speechSelectedRange = NSRange()
  @State var lastKeyPress: _KeyPress?
  @State var lastReturnEventTime = 0.0
  @State private var lastReceivedText = ""

  @State var historySelection: Message?
  @State var completionSelection: AttributedString?

  @State private var showDocumentPicker = false

  @FocusState private var focusedField: FocusedField?

  @Binding var messages: [Message]
  let saveAction: () -> Void

  @Binding var completions: [AttributedString]

  @State var triggeredCorrectAutomatically = false

  @State private var error: Error? = nil
  var isShowingError: Binding<Bool> {
    Binding {
      error != nil
    } set: { _ in
      error = nil
    }
  }

  var isShowingCompletions: Bool {
    CompletionManager.shared.isCompleting
  }

  // This is special binding to make our TextView ignore keystrokes
  // when we are in completion mode.
  var rejectAllInput: Binding<Bool> {
    Binding {
      isShowingCompletions
    } set: { _ in
      // ignored, the is read only
    }
  }

  func setSpeechText(_ s: String) {
    speechText = NSAttributedString(string: s)
    if s.isEmpty {
      historySelection = nil
      triggeredCorrectAutomatically = false
    }
  }

  var body: some View {
    NavigationStack {
      VStack {
        if isShowingCompletions {
          CompletionListView(items: $completions, selection: $completionSelection)
        } else {
          ListView(messages: $messages, selection: $historySelection, saveAction: saveAction)
        }

        TextView(
          text: $speechText, lastKeyPress: $lastKeyPress, selectedRange: $speechSelectedRange,
          rejectAllInput: rejectAllInput
        )
        .cornerRadius(6.0)
        .overlay(RoundedRectangle(cornerRadius: 6).inset(by: -5).stroke(.secondary, lineWidth: 2))
        .padding()
        .focused($focusedField, equals: .speechText)
        .onAppear {
          self.focusedField = .speechText
        }
        .onChange(of: historySelection) {
          if let row = historySelection {
            setSpeechText(row.message)
          }
        }
        .onChange(of: completionSelection) {
          if let text = completionSelection {
            setSpeechText(text.string)
            speechSelectedRange = NSRange(location: 0, length: text.string.utf16.count)
          }
        }
        .onChange(of: speechSelectedRange) {
          // If there is a touch in the text view, assume that is accepting the current completion.
          if isShowingCompletions && speechSelectedRange.length == 0 {
            CompletionManager.shared.accept()
          }
        }
        .onChange(of: lastKeyPress) {
          // Use this to emulate/unify key event handling.
          if let evt = lastKeyPress {
            _ = textViewKeyDown(evt: evt)
          }
        }
        .onKeyPress(phases: [.down]) { evt in
          if evt.modifiers.contains(.command) || !evt.key.character.isASCII || evt.key == .escape
            // This is a bit of a hodge podge of rules. I wish it were more consistent.
            || (evt.modifiers.contains(.shift) && evt.key.character.isWhitespace)
          {
            // This only works when a physical keyboard is connected.
            // Doing events here makes sure the TextView has focus.
            // Defining keyboardShortcuts on menu items does not seem reliable at all,
            // even when testing on a real device.
            return textViewKeyDown(evt: _KeyPress(evt: evt))
          }
          return .ignored
        }
        .frame(minHeight: 30, maxHeight: 120)

        // https://www.hackingwithswift.com/example-code/uikit/how-to-adjust-a-uiscrollview-to-fit-the-keyboard
        HStack {
          if UIDevice.current.userInterfaceIdiom == .phone {
            Button(action: softTabKey) {
              Text("Tab")
            }.buttonStyle(.bordered).lineLimit(1)
          }
          Button(action: ringBell) {
            if UIDevice.current.userInterfaceIdiom == .phone {
              Text("🛎️")
            } else {
              Text("🛎️ Ring Bell")
            }
          }.buttonStyle(.bordered).padding()
            .keyboardShortcut("r", modifiers: [.command])
          Button(action: ringBellLoud) {
            if UIDevice.current.userInterfaceIdiom == .phone {
              Text("🛎️🛎️")
            } else {
              Text("🛎️🛎️ Ring BELL!")
            }
          }.buttonStyle(.bordered).lineLimit(1)
            .keyboardShortcut("r", modifiers: [.command, .shift])
          Spacer()
          Button(action: clearText) {
            if UIDevice.current.userInterfaceIdiom == .phone {
              Text("❌")
            } else {
              Text("❌ Clear")
            }
          }.buttonStyle(.bordered).padding()
          Spacer()
          Button(action: sayText) {
            if UIDevice.current.userInterfaceIdiom == .phone {
              Text("📣")
            } else {
              Text("📣 Say")
            }
          }.buttonStyle(.bordered).padding()
        }
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          // NOTE: These items don't seem to have fire when they have a keyboard shortcut assigned.
          Menu("Chat") {
            Section {
              Toggle("Noisy Typing", isOn: $noisyTyping)
              Toggle("Speak Sentences Automatically", isOn: $speakSentencesAutomatically)
              Toggle("Ignore Useless Keys", isOn: $ignoreUselessKeys)
              Toggle("Disable Screen Lock", isOn: $disableScreenLock)
              Toggle("Log Chat History", isOn: $logChatHistory)
            }
            // FIXME: disable until Mavis the Mac version is more generally functional?
            //            Section {
            //              Toggle("Enable Text Corrector", isOn: $enableCorrectorService)
            //              Toggle("Show Corrections Automatically", isOn: $showCorrectionsAutomatically)
            //                .disabled(!enableCorrectorService)
            //            }
            Section {
              Button("Clear History", action: clearHistory)
            }
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          NavigationLink("Settings") {
            PrefsView()
          }
        }
      }
      .sheet(isPresented: $showDocumentPicker) {
        DocumentPickerView(error: $error)
      }
      .alert(isPresented: isShowingError) {
        Alert(
          title: Text("Error"),
          message: Text(error?.localizedDescription ?? "Unknown error"),
          dismissButton: .default(Text("OK"))
        )
      }
    }
    .onAppear {
      if disableScreenLock {
        SleepManager.shared.deferSleep(Prefs.shared.screenLockMinutes * 60.0)
      }
      UIApplication.shared.isIdleTimerDisabled = disableScreenLock
      print("nav appear, set disableScreenLock: \(disableScreenLock)")
    }
    .onReceive(
      NotificationCenter.default.publisher(
        for: UIScene.willEnterForegroundNotification)
    ) { _ in
      if disableScreenLock {
        SleepManager.shared.deferSleep(Prefs.shared.screenLockMinutes * 60.0)
      }
      UIApplication.shared.isIdleTimerDisabled = disableScreenLock
      print("enter foreground, set disableScreenLock: \(disableScreenLock)")
    }
    .onReceive(
      NotificationCenter.default.publisher(
        for: UIScene.didEnterBackgroundNotification)
    ) { _ in
      UIApplication.shared.isIdleTimerDisabled = false
      print("enter background, re-enable screen lock")
    }
  }

  // The iPhone does not get a tab key, so give it one for consistency.
  private func softTabKey() {
    _ = textViewKeyDown(evt: _KeyPress(characters: "\t"))
  }

  func textViewKeyDown(evt: _KeyPress) -> KeyPress.Result {
    if evt.key == .return {
      let now = NSDate.now.timeIntervalSince1970
      let interval = now - lastReturnEventTime
      lastReturnEventTime = now
      if interval < Prefs.shared.minReturnKeyDelay {
        // Squelch rapid return events, but play a noise so there is some indication
        // that something happened.
        AudioManager.shared.play(
          file: boopSoundFile, volume: Float(Prefs.shared.boopVolume))
        return .handled
      }
    }
    if isShowingCompletions {
      return textViewKeyDownCompletion(evt: evt)
    }
    return textViewKeyDownEditing(evt: evt)
  }

  func textViewKeyDownCompletion(evt: _KeyPress) -> KeyPress.Result {
    if evt.key == .return {
      if !CompletionManager.shared.completions.isEmpty {
        CompletionManager.shared.accept()
      }
      return .handled
    } else if evt.key == .escape {
      CompletionManager.shared.cancel()
      return .handled
    } else if evt.key == .delete {
      // Ignore delete for now.
      return .handled
    } else if evt.key == .tab {
      if evt.modifiers.contains(.shift) {
        selectNextCompletion()
      } else {
        selectPreviousCompletion()
      }
      return .handled
    } else if evt.key == .upArrow {
      selectPreviousCompletion()
      return .handled
    } else if evt.key == .downArrow {
      selectNextCompletion()
      return .handled
    } else if evt.key.character.isASCII {
      // FIXME: perhaps we should be using evt.characters here
      // to handle swipe input.
      updateCompletion(forCharacter: evt.key.character)
      return .handled
    }

    completionSelection = nil
    return .ignored
  }

  func textViewKeyDownEditing(evt: _KeyPress) -> KeyPress.Result {
    if evt.modifiers.contains(.command) {
      if evt.key == .upArrow {
        selectPreviousHistoryItem()
        return .handled
      } else if evt.key == .downArrow {
        selectNextHistoryItem()
        return .handled
      } else if evt.key == .return {
        sayAgain()
        return .handled
      } else if evt.key == .delete {
        setSpeechText("")
        return .handled
      }
    } else if evt.key == .return {
      sayText()
      return .handled
    } else if evt.key == .tab {
      CompletionManager.shared.showCompletion(
        textViewString: $speechText, textViewSelection: $speechSelectedRange,
        withSelectedItem: $completionSelection)
      return .handled
    } else {
      triggeredCorrectAutomatically = false
      if noisyTyping {
        AudioManager.shared.play(
          file: keyClickSoundFile, volume: Float(Prefs.shared.keyClickVolume))
      }
      if evt.key == .space {
        electricPunctuation()
      }
    }
    historySelection = nil
    return .ignored
  }

  func clearHistory() {
    messages.removeAll()
    saveAction()
  }

  func clearText() {
    if isShowingCompletions {
      CompletionManager.shared.cancel()
    } else {
      setSpeechText("")
    }
    historySelection = nil
  }

  func selectPreviousHistoryItem() {
    if messages.count == 0 {
      return
    }
    if historySelection == nil {
      historySelection = messages.last
    } else {
      var i = messages.firstIndex(of: historySelection!)
      if i != nil {
        i = max(i! - 1, 0)
        historySelection = messages[i!]
      }
    }
    setSpeechText(historySelection!.message)
  }

  func selectNextHistoryItem() {
    if messages.count == 0 {
      return
    }
    if historySelection == nil {
      historySelection = messages.first
    } else {
      var i = messages.firstIndex(of: historySelection!)
      if i != nil {
        i = min(i! + 1, messages.count - 1)
        historySelection = messages[i!]
      }
    }
    setSpeechText(historySelection!.message)
  }

  func ringBell() {
    AudioManager.shared.play(file: bellSoundFile, volume: Float(Prefs.shared.bellVolume))
  }

  func ringBellLoud() {
    AudioManager.shared.play(file: loudBellSoundFile, volume: Float(Prefs.shared.loudBellVolume))
  }

  private func speakAloud(text: String, automatically: Bool) {
    // FIXME: track automatic sentence speaking?
    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return
    }
    SpeechManager.shared.say(
      text: text, voice: SpeechManager.shared.voice, rate: Float(Prefs.shared.speechRate),
      pitch: Float(Prefs.shared.speechPitch), volume: Float(Prefs.shared.speechVolume))
    if logChatHistory {
      LogStore.shared.log(
        string: text, withInputKeystrokes: "", withAnnotations: ["automatic": automatically])
    }
  }

  private func _sayText() {
    // Due to how we emulate the return key with a button, we have to handle
    // completion state.
    if isShowingCompletions {
      CompletionManager.shared.accept()
      return
    }

    let str = speechText.string.trimmingCharacters(in: .whitespacesAndNewlines)
    if str == "" {
      SpeechManager.shared.stop()
      return
    }

    let unspokenText = speechText.attributedSubstring(from: unspokenTextRange()).string
      .trimmingCharacters(in: .whitespacesAndNewlines)

    // Automatic sentence speaking and automatic corrections don't work so well together.
    // We don't correct things automatically spoken right now, as that would probably
    // be disruptive and defeat the purpose.
    // However, we can preserve the correct-on-return behavior as long as nothing has
    // been spoken yet. If there is partial speach, the completion UI becomes even
    // more complicated and likely frustrating.
    if !triggeredCorrectAutomatically {
      if Prefs.shared.showCorrectionsAutomatically
        && Prefs.shared.enableCorrectorService && str == unspokenText
      {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: str.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(
          in: str, range: range, startingAt: 0, wrap: false, language: "en_US")

        if misspelledRange.location != NSNotFound {
          triggeredCorrectAutomatically = true
          CompletionManager.shared.showCompletion(
            textViewString: $speechText, textViewSelection: $speechSelectedRange,
            withSelectedItem: $completionSelection)
          // Hardcode the volume for now, it's an alert that further action is required.
          AudioManager.shared.play(
            file: boopSoundFile, volume: Float(Prefs.shared.boopVolume))
          return
        }
      }
    }
    triggeredCorrectAutomatically = false

    speakAloud(text: unspokenText, automatically: false)

    withAnimation {
      messages.removeAll { msg in msg.message == str }
      while messages.count > 9 {
        messages.remove(at: 0)
      }
      let newMessage = Message(
        id: Int(Date().timeIntervalSince1970 * 1e9),
        message: str)
      messages.append(newMessage)
      saveAction()
      setSpeechText("")
    }
  }

  private func sayText() {
    // FIXME: it's unclear how to solve this. When called from onKeyPress,
    // the code inside _sayText() can't remove items from messages. I have no idea why.
    // It works when the "Say" button is pressed, or the delete action is triggered.
    DispatchQueue.main.async {
      _sayText()
    }
  }

  // NOTE: The function doesn't get called more than once from the simulator,
  // yet works fine on device. Is this a code bug or a simulator bug? Who knows.
  private func sayAgain() {
    selectPreviousHistoryItem()
    sayText()
  }

  private func unspokenTextRange() -> NSRange {
    let allRange = NSMakeRange(0, speechText.length)
    var attrRange = NSMakeRange(0, 0)
    let attrs = speechText.attributes(at: 0, longestEffectiveRange: &attrRange, in: allRange)

    let sayRange: NSRange
    if NSEqualRanges(attrRange, allRange) {
      if attrs[MavisAttrKey] as? String == MavisAttrSpoken {
        // Everything has been spoken.
        return NSMakeRange(0, 0)
      }
      // Nothing spoken yet.
      sayRange = allRange
    } else {
      sayRange = NSMakeRange(attrRange.length, speechText.length - attrRange.length)
      print("unspokenTextRange ", sayRange)
    }
    return sayRange
  }

  private func electricPunctuation() {
    if !Prefs.shared.speakSentencesAutomatically {
      return
    }

    let str = speechText.string.trimmingCharacters(in: CharacterSet.whitespaces)
    guard let lastChar = str.last else {
      return
    }

    if !".!?".contains(String(lastChar)) {
      return
    }

    let sayRange = unspokenTextRange()
    if sayRange.length == 0 {
      return
    }
    let sayStr = speechText.attributedSubstring(from: sayRange)
    let tokens = CompletionManager.tokenizeText(text: sayStr.string)
    let idx = tokens.count - 1
    if idx >= 0 {
      let punc = tokens[idx]
      if punc == "." && idx > 1 {
        // Don't trigger on common abbreviations.
        let precedingToken = tokens[idx - 1].lowercased()
        // Ignore if this is a well-know abbreviation.
        // We just shouldn't even bother with these, it's not helpful to type them,
        // but maybe this will help once in a while.
        if commonAbbreviations.contains(precedingToken) {
          return
        }
      }
    }

    var attrs = speechText.attributes(at: 0, effectiveRange: nil)
    attrs[MavisAttrKey] = MavisAttrSpoken
    attrs[NSAttributedString.Key.backgroundColor] = UIColor.darkGray
    if let newText = speechText.mutableCopy() as? NSMutableAttributedString {
      newText.setAttributes(attrs, range: sayRange)
      speechText = newText
    }
    speakAloud(text: sayStr.string, automatically: true)
  }

  func selectPreviousCompletion() {
    if completions.count == 0 {
      return
    }
    if completionSelection == nil {
      completionSelection = completions.last
    } else {
      var i = completions.firstIndex(where: { $0.string == completionSelection?.string })
      if i != nil {
        i = max(i! - 1, 0)
        completionSelection = completions[i!]
      }
    }
    if let text = completionSelection {
      setCompletionText(text: text.string)
    }
  }

  func setCompletionText(text: String) {
    setSpeechText(text)
  }

  func selectNextCompletion() {
    if completions.count == 0 {
      return
    }
    if completionSelection == nil {
      completionSelection = completions.first
    } else {
      var i = completions.firstIndex(where: { $0.string == completionSelection?.string })
      if i != nil {
        i = min(i! + 1, completions.count - 1)
        completionSelection = completions[i!]
      }
    }
    if let text = completionSelection {
      setCompletionText(text: text.string)
    }
  }

  func updateCompletion(forCharacter char: Character) {
    CompletionManager.shared.refineCompletion(withString: String(char))
  }
}

// Missing functionality in SwiftUI for sure.
extension View {
  func hidden(_ shouldHide: Bool) -> some View {
    opacity(shouldHide ? 0 : 1)
  }
}

extension AttributedString {
  var string: String {
    String(self.characters)
  }
}

let funnyMessages = [
  "I ate vegan Welsh rarebit.",
  "How much wood would a wood chuck chuck if a woodchuck could chuck wood?",
  "I feel like the whole world has gone super crazy around me. Luckily, I'm still normal.",
  "And what happens when we run out of space? Surely they will have thought of this, right?",
  "I should have a podcast",
  "I've made some poor life choices.",
  "Probably 3.",
  "Boy this work's hard.",
  "Hand me that thing.",
  "Guys, break's over.",
]

func makeMessages() -> [Message] {
  var ml = [Message]()
  let now = Int(Date().timeIntervalSince1970 * 1e9)

  for (i, message) in funnyMessages.enumerated() {
    let id = now + i
    ml.append(Message(id: id, message: message))
  }
  return ml
}

let sampleMessages: [Message] = makeMessages()

#Preview {
  ContentView(
    messages: .constant(sampleMessages),
    saveAction: {},
    completions: .constant([
      "A",
      "B",
      "C",
    ])
  )
}
