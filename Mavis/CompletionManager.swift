import Foundation
import SwiftUI
import UIKit

struct ScoredString: Comparable {
  // Sort by highest score and then alphabetically.
  static func < (lhs: ScoredString, rhs: ScoredString) -> Bool {
    if lhs.score < rhs.score {
      return true
    } else if lhs.score == rhs.score && lhs.string > rhs.string {
      return true
    }
    return false

  }

  var score: Double
  var string: String
}

@Observable
class CompletionManager: ObservableObject {
  var completions: [AttributedString] = []
  var isCompleting = false

  var textViewString: Binding<NSAttributedString>? = nil
  var textViewSelection: Binding<NSRange>? = nil
  var listViewSelection: Binding<AttributedString?>? = nil

  // Refinement is extra, non-visible characters we use to further
  // narrow selection. The UI here isn't great - it's more like MacOS
  // where key events help navigate lists.
  private var refinement = ""
  private var allowRefinement = false

  // Track a task providing completions so we can cancel if necessary.
  private var completionTask: URLSessionDataTask? = nil

  private var phrases: [String] = []

  private var originalText = ""
  private var originalSelection = NSRange()  // what was the original selection when completing started?
  private var originalRange = NSRange()  // what was the original span of completing words?

  private var stringCompletions: [String] {
    var l: [String] = []
    for s in completions {
      l.append(s.string)
    }
    return l
  }

  static let shared = CompletionManager()

  static func normalizeToken(token: String) -> String {
    return token.lowercased()
  }

  // Returns and array of words, spaces and punctuation that can be returned to the original
  // string with componentsJoinedByString:@"". This is a lossless function.
  static func tokenizeText(text: String) -> [String] {
    var tokens: [String] = []
    var nextToken: [Character] = []
    for c in text {
      switch c {
      case " ", ".", ",", "!", "?", "-":
        tokens.append(String(nextToken))
        tokens.append(String(c))
        nextToken = []
      default:
        nextToken.append(c)
      }
    }
    if !nextToken.isEmpty {
      tokens.append(String(nextToken))
    }
    return tokens
  }

  // Strip common punctuation and return and array of normalized words. This is a lossy function.
  static func tokenizeIntoWords(string: String) -> [String] {
    // Interesting tokenizations: split on -, strip ',!.
    var str = string
    for c in "'’,.!?" {
      str = str.replacingOccurrences(of: String(c), with: "")
    }
    // FIXME: hyphens and apostrophes need to be expanded to (token, pos) to help with scoring, but
    // let's not get too far ahead.
    str = str.replacingOccurrences(of: "-", with: " ")
    var tokens: [String] = []
    for t in str.components(separatedBy: CharacterSet(charactersIn: " ")) {
      if t.count > 0 {
        tokens.append(normalizeToken(token: t))
      }
    }
    return tokens
  }

  private func readFiles() {
    // FIXME: Feels sloppy/expensive to recompute this every time.
    // It's not correct to only merge this when the phrases change.
    // Realistically, phrase changing is probably way more likely and soundbites.
    let soundbites = SpeechManager.shared.soundbites
    let fm = MVFileManager.shared
    do {
      if let phrases = try fm.readFileDataAsStringArrayIfModified(fileURL: fm.phrases) {
        self.phrases = phrases
      }
    } catch CocoaError.fileNoSuchFile {
      // Just ignore - not everyone will have a file.
    } catch {
      print("failed reading phrases \(error)")
    }

    phrases = Set(phrases).union(soundbites).sorted()

    var wordSet = Set<String>()
    for p in phrases {
      for t in CompletionManager.tokenizeText(text: p) {
        wordSet.insert(t)
      }
    }
    var missing = Set<String>()
    let checker = UITextChecker()
    for w in wordSet {
      // Scan all our phrases and soundbites so we don't accidentally consider them misspelled.
      let errorRange = checker.rangeOfMisspelledWord(
        in: w, range: NSRange(location: 0, length: w.utf16.count), startingAt: 0, wrap: false,
        language: "en")
      if errorRange.location != NSNotFound {
        missing.insert(w)
      }
    }
    if missing.count > 0 {
      print("add missing words to dictionary:", missing.sorted().joined(separator: ", "))
      for w in missing {
        UITextChecker.learnWord(w)
      }
    }
  }

  func scoreStrings(strings: [String], against str: String) -> [String] {
    // FIXME: maybe score should get scaled by the length of the term,
    // or it's frequency in the "corpus".
    var scored: [ScoredString] = []
    let qTokens = Self.tokenizeIntoWords(string: str)
    for s in strings {
      let words = Self.tokenizeIntoWords(string: s)
      var score = 0.0
      for j in 0..<qTokens.count {
        let t = qTokens[j]
        var idx = words.firstIndex(of: t)
        if idx != nil {
          // Token matched a word.
          score += 1.0
        } else {
          for wi in 0..<words.count {
            if words[wi].hasPrefix(t) {
              // Token matched a word prefix
              idx = wi
              score += 0.5
              break
            }
          }
        }
        if idx == j {
          // Matched token position.
          score += 1.0
        }
      }
      if score > 0 {
        scored.append(ScoredString(score: score, string: s))
      }
    }
    if scored.isEmpty {
      return []
    }
    var sl: [String] = []
    for ss in scored.sorted().reversed() {
      sl.append(ss.string)
    }
    return sl
  }

  func completions(forPartialString str: String, withContext context: String) -> [AttributedString]?
  {
    allowRefinement = false
    readFiles()
    // context is the whole message
    // str is probably the last token, which is probably partial (but not necessarily), but could also be the whole
    // context.
    let words = Self.tokenizeIntoWords(string: str)

    if words.isEmpty {
      // FIXME: return quick replies? Not really sure this gets used.
      return nil
    }

    if words.count == 1 {
      if let tok = words.last {
        if tok == "z" {
          allowRefinement = true
          return styleCompletions(
            completions: phrases, forText: context, highlightDifferences: false)
        }
      }
    }

    if Prefs.shared.enableCorrectorService {
      if let addr = ZeroConfController.shared.resolvedAddr {
        var url = URL(string: "http://\(addr)/correct")!
        url.append(queryItems: [URLQueryItem(name: "text", value: context)])

        let svc = CompletionService()
        completionTask = svc.fetchData(
          from: url,
          completion: {
            self.completionTask = nil
            // If we don't return in time, just set our data as the only completion.
            // This isn't useful, but it's better than nothing, since automatically
            // cancelling the action might prove seemingly unpredictable to the speaker.
            var values = svc.reply?.returnValue ?? [context]
            if values.isEmpty {
              values = [context]
            }
            // FIXME: does this need to be run on the MainActor?
            self.setCompletions(
              self.styleCompletions(
                completions: values, forText: context, highlightDifferences: true)
            )
          })
        // Return nothing for now, the fetch callback will fill
        // in the completions.
        return nil
      }
      return self.styleCompletions(
        completions: [context], forText: context, highlightDifferences: false)
    } else {
      // FIXME: We should be able to go back to scanning other type of completions here,
      // but this has been buggy.
      let strList = scoreStrings(strings: phrases, against: str)
      return styleCompletions(completions: strList, forText: context, highlightDifferences: false)
    }
  }

  func styleCompletions(completions: [String], forText context: String, highlightDifferences: Bool)
    -> [AttributedString]
  {
    var fancyCompletions: [AttributedString] = []
    if !highlightDifferences {
      for s in completions {
        fancyCompletions.append(AttributedString(s))
      }
      return fancyCompletions
    }

    let defaultAttrs = AttributeContainer()
    var highlightAttrs = AttributeContainer()
    // NOTE: This incantation is hard to fine, but separately setting
    // the attributes for underlineColor do not work.
    highlightAttrs.underlineStyle = Text.LineStyle(pattern: .solid, color: .red)

    let space = AttributedString(" ")

    let originalWords = context.lowercased().split(separator: " ")
    for s in completions {
      // It's very hard to spot corrections make against the original, so highlight them.
      var ns = AttributedString()

      let cWords = s.split(separator: " ")
      var first = true
      for w in cWords {
        if !first {
          ns.append(space)
        } else {
          first = false
        }

        var attrs = defaultAttrs
        // Use case-insensitive comparison
        if !originalWords.contains(String.SubSequence(w.lowercased())) {
          attrs = highlightAttrs
        }
        ns.append(AttributedString(w, attributes: attrs))
      }

      fancyCompletions.append(ns)
    }
    return fancyCompletions
  }

  func rangeForCompletion(_ str: String, startingRange: NSRange) -> NSRange {
    return NSRange(location: 0, length: str.count)
  }

  // completions should be sorted best-to-worst
  private func setCompletions(_ completions: [AttributedString]) {
    // Reverse the order, since our UI is inverted.
    self.completions = completions.reversed()
    self.listViewSelection?.wrappedValue = self.completions.last
  }

  @MainActor
  func showCompletion(
    textViewString: Binding<NSAttributedString>, textViewSelection: Binding<NSRange>,
    withSelectedItem selectedItem: Binding<AttributedString?>
  ) {
    self.isCompleting = true
    self.textViewString = textViewString
    self.textViewSelection = textViewSelection
    self.listViewSelection = selectedItem

    originalSelection = textViewSelection.wrappedValue
    let text = textViewString.wrappedValue.string
    let range = textViewSelection.wrappedValue
    originalRange = rangeForCompletion(text, startingRange: range)

    if let r = Range(originalRange, in: text) {
      originalText = String(textViewString.wrappedValue.string[r])
    }
    selectedItem.wrappedValue = nil
    if let sortedCompletions = completions(
      forPartialString: originalText, withContext: textViewString.wrappedValue.string)
    {
      setCompletions(sortedCompletions)
    }

    //    print("showCompletions", completions)
  }

  @MainActor
  func refineCompletion(withString str: String) {
    refinement = refinement.appending(str).lowercased()
    if !allowRefinement {
      return
    }
    // This is more complicated than it seems in terms of getting a useful behavior.
    // It's not clear the target audience will be able to make use of this.
    //
    // It seems like the correct behavior is to refine what was initially returned, so
    // each refined result is a strict subset of the previous items, say in terms of a
    // list of soundbites. However in a list of corrections, the individual results
    // are all so similar that this is less useful.
    var refined: [AttributedString] = []
    for c in completions {
      let r = c.string.lowercased().ranges(of: refinement)
      if !r.isEmpty {
        refined.append(c)
      }
    }
    if !refined.isEmpty {
      // print("refine completion: '\(refinement)'", refined)
      completions = refined
      listViewSelection?.wrappedValue = completions.last
    }

  }

  @MainActor
  func update(text: String) {
    let newStr = originalText.replacingCharacters(
      in: Range(originalRange, in: originalText)!, with: text)
    textViewString?.wrappedValue = NSAttributedString(string: newStr)
    textViewSelection?.wrappedValue = NSRange(location: originalRange.location, length: text.count)
  }

  private func reset() {
    self.isCompleting = false
    completions = []
    refinement = ""
    listViewSelection?.wrappedValue = nil
    if let task = completionTask {
      print("cancel completionTask")
      task.cancel()
    }
  }

  @MainActor
  func cancel() {
    LogStore.shared.log(
      string: originalText, withInputKeystrokes: "",
      withAnnotations: [
        "completeAccepted": false,
        "completionText": originalText,
        "completions": stringCompletions,
      ])
    reset()
    update(text: self.originalText)
    textViewSelection?.wrappedValue = self.originalSelection
  }

  @MainActor
  func accept() {
    // Due to races in filling in completions, it's possible that a return
    // can get routed here even when there is nothing to accept, so we
    // treat that as a cancel.
    if completions.isEmpty {
      cancel()
      return
    }
    let str = textViewString?.wrappedValue.string ?? ""
    LogStore.shared.log(
      string: str, withInputKeystrokes: "",
      withAnnotations: [
        "completeAccepted": true,
        "completionText": originalText,
        // FIXME: log refinement?
        "completions": stringCompletions,
      ])

    reset()
    update(text: str)
  }
}

struct CompletionListView: View {
  @Binding var items: [AttributedString]
  @Binding var selection: AttributedString?

  var body: some View {
    GeometryReader { geometry in
      ScrollViewReader { scrollView in
        if items.isEmpty {
          ProgressView().progressViewStyle(CircularProgressViewStyle())
        }
        List(selection: $selection) {
          ForEach(items, id: \.self) { row in
            Text(row)
              .tag(row)
              .listRowBackground(
                selection == row ? Color(.systemFill) : Color(.systemBackground))
          }
        }
        .onAppear {
          scrollToSelection(scrollView)
        }
        .onChange(of: items) {
          scrollToSelection(scrollView)
        }
        .onChange(of: selection) {
          scrollToSelection(scrollView)
        }
        .onChange(of: geometry.size) {
          // FIXME: This defer is obviously garbage, but without it
          // there are number of times that items are left hidden after
          // the keyboard or itemAccessoryView show up.
          scrollToSelection(scrollView)
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.750) {
            scrollToSelection(scrollView)
          }
        }
        .scrollContentBackground(.hidden)
      }
    }
  }

  private func scrollToSelection(_ scrollView: ScrollViewProxy) {
    if items.count > 0 {
      if let str = selection {
        scrollView.scrollTo(str, anchor: .bottom)
      }
    }
  }
}
