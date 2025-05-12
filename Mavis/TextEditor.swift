import SwiftUI

let allowedCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-,!?' "

struct TextView: UIViewRepresentable {

  @Binding var text: NSAttributedString
  @Binding var lastKeyPress: _KeyPress?
  @Binding var selectedRange: NSRange
  // We need a "soft" version of focus. The text control must truly have focus so
  // that it will received key and text insert events. However, we want to ignore
  // these when we are in completion mode, so we need a secondary version of focus.
  @Binding var rejectAllInput: Bool
  @Preference(\.fontSize) var fontSize
  @Preference(\.enableInlineTextCorrections) var enableInlineTextCorrections
  @Preference(\.enableInlineTextPredictions) var enableInlineTextPredictions

  func makeCoordinator() -> Coordinator {
    return Coordinator(
      $text, $lastKeyPress, $selectedRange, $rejectAllInput, $enableInlineTextCorrections,
      $enableInlineTextPredictions)
  }

  class Coordinator: NSObject, UITextViewDelegate {
    var text: Binding<NSAttributedString>
    var lastKeyPress: Binding<_KeyPress?>
    var selectedRange: Binding<NSRange>
    var rejectAllInput: Binding<Bool>
    var enableInlineTextCorrections: Binding<Bool>
    var enableInlineTextPredictions: Binding<Bool>

    init(
      _ text: Binding<NSAttributedString>, _ lastKeyPress: Binding<_KeyPress?>,
      _ selectedRange: Binding<NSRange>, _ rejectAllInput: Binding<Bool>,
      _ enableInlineTextCorrections: Binding<Bool>,
      _ enableInlineTextPredictions: Binding<Bool>
    ) {
      self.text = text
      self.lastKeyPress = lastKeyPress
      self.selectedRange = selectedRange
      self.rejectAllInput = rejectAllInput
      self.enableInlineTextCorrections = enableInlineTextCorrections
      self.enableInlineTextPredictions = enableInlineTextPredictions
    }

    // Values need to be updated async, to "queue" them.
    // This obviously is a bad sign. The idea came from:
    // https://chris.eidhof.nl/post/view-representable/
    func textViewDidChange(_ textView: UITextView) {
      DispatchQueue.main.async {
        self.text.wrappedValue = textView.attributedText
      }
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
      DispatchQueue.main.async {
        self.selectedRange.wrappedValue = textView.selectedRange
      }
    }

    func textView(
      _ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String
    ) -> Bool {
      if text.count <= 1 {
        // "delete" is an empty string.
        let evt = _KeyPress(characters: text)
        DispatchQueue.main.async {
          self.lastKeyPress.wrappedValue = evt
        }
      }
      if text.count == 1 && Prefs.shared.ignoreUselessKeys && !allowedCharacters.contains(text) {
        return false
      }
      return !rejectAllInput.wrappedValue
    }

    lazy var textView: UITextView = {
      let textView = UITextView()

      textView.delegate = self
      textView.isSelectable = true
      textView.isUserInteractionEnabled = true
      textView.textColor = UIColor.label
      //            textView.font = font()

      // Disable smart quotes and things
      textView.typingAttributes = defaultAttrs
      textView.keyboardType = .asciiCapable
      textView.smartQuotesType = .no
      textView.smartDashesType = .no
      textView.autocapitalizationType = .sentences
      textView.spellCheckingType = .yes
      textView.autocorrectionType = enableInlineTextCorrections.wrappedValue ? .yes : .no
      textView.inlinePredictionType = enableInlineTextPredictions.wrappedValue ? .yes : .no
      return textView
    }()
  }

  func makeUIView(context: Context) -> UITextView {
    context.coordinator.textView.font = font()
    return context.coordinator.textView
  }

  func font() -> UIFont {
    return UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body).withSize(fontSize)
  }

  func updateUIView(_ uiView: UITextView, context: Context) {
    // Based on some examples, we need to conditionally
    // propagate some values from our state back into UIKit.
    // I'm still fuzzy on which attributes those are, and it's
    // not clear that you can know ahead of time.

    // NOTE: The order here is important, set the defaults and then set the
    // attributedText otherwise the behavior in the text view is
    // unpredictable.
    // FIXME: do real comparison? this may not be necessary
    if uiView.typingAttributes.count != defaultAttrs.count {
      //            print("update attrs", uiView.typingAttributes,defaultAttrs )
      uiView.typingAttributes = defaultAttrs
    }
    if uiView.attributedText != text {
      //            print("update text", uiView.attributedText!, "->", text)
      uiView.attributedText = text
    }
    if selectedRange.length != uiView.selectedRange.length
      || selectedRange.location != uiView.selectedRange.location
    {
      //            print("update range old", uiView.selectedRange, "new", selectedRange)
      uiView.selectedRange = selectedRange
    }
    if uiView.textColor != UIColor.label {
      //            print("update color", uiView.textColor, UIColor.label)
      uiView.textColor = UIColor.label
    }
    let f = font()
    if uiView.font != f {
      //            print("update font", uiView.font, f)
      uiView.font = f
    }
    uiView.autocorrectionType = enableInlineTextCorrections ? .yes : .no
    uiView.inlinePredictionType = enableInlineTextPredictions ? .yes : .no
  }
}

#Preview {
  struct Pview: View {
    @State var aStr = NSAttributedString("test")
    @State var range = NSRange()
    @State var lastEvent: _KeyPress?
    @State var rejectAllInput = false
    var body: some View {
      Form {
        let s = AttributedString("Beware - this preview often has erratic bugs in the simulator")
        Text(s)

        TextView(
          text: $aStr, lastKeyPress: $lastEvent, selectedRange: $range,
          rejectAllInput: $rejectAllInput)

        Button("Test Select All") {
          range = NSMakeRange(0, aStr.string.count)
        }
      }
    }
  }
  return Pview()
}
