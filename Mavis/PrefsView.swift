import AVFoundation
import SwiftUI

struct PrefsView: View {

  @Preference(\.speechVoiceIdentifier) var speechVoiceIdentifier
  @Preference(\.speechRate) var speechRate
  @Preference(\.speechPitch) var speechPitch
  @Preference(\.speechVolume) var speechVolume
  @Preference(\.bellVolume) var bellVolume
  @Preference(\.boopVolume) var boopVolume
  @Preference(\.loudBellVolume) var loudBellVolume
  @Preference(\.keyClickVolume) var keyClickVolume
  @Preference(\.fontSize) var fontSize
  @Preference(\.screenLockMinutes) var screenLockMinutes
  @Preference(\.minReturnKeyDelay) var minReturnKeyDelay
  @Preference(\.enableInlineTextCorrections) var enableInlineTextCorrections
  @Preference(\.enableInlineTextPredictions) var enableInlineTextPredictions

  @State var shareFile: ShareFile?
  @State private var showDocumentPicker = false

  @State private var error: Error? = nil
  var isShowingError: Binding<Bool> {
    Binding {
      error != nil
    } set: { _ in
      error = nil
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("Voice Controls")) {
          Grid(
            alignment: .leading,
            horizontalSpacing: 10,
            verticalSpacing: 5
          ) {
            GridRow {
              Text("Voice:").frame(alignment: .trailing)
              Picker("", selection: $speechVoiceIdentifier) {
                ForEach(SpeechManager.shared.getVoices()) { voice in
                  Text(voice.name).tag(voice.identifier)
                }
              }
              // gridCellColumns shrinks the center of the subsequent rows. very odd.
              // .gridCellColumns(1).border(.red)
            }

            FormSliderRow(text: "Rate:", value: $speechRate, range: 0...1)
            FormSliderRow(text: "Pitch:", value: $speechPitch, range: 0.75...1.25)
            FormSliderRow(text: "Volume:", value: $speechVolume, range: 0...1)
          }
        }
        Section(header: Text("Sound Effects")) {
          Grid(
            alignment: .leading,
            horizontalSpacing: 10,
            verticalSpacing: 5
          ) {

            FormSliderRow(text: "Bell Volume:", value: $bellVolume, range: 0...1)
            FormSliderRow(text: "Loud Bell Volume:", value: $loudBellVolume, range: 0...1)
            FormSliderRow(text: "Key Click Volume:", value: $keyClickVolume, range: 0...1)
            FormSliderRow(text: "Error Volume:", value: $boopVolume, range: 0...1)
          }
        }
        Section(header: Text("Input")) {
          Grid(
            alignment: .leading,
            horizontalSpacing: 10,
            verticalSpacing: 5
          ) {
            FormSliderRow(
              text: "Minimum Return Key Delay:", value: $minReturnKeyDelay, range: 0...1,
              step: 0.05,
              helpMessage:
                "Ignore multiple presses of the return key if they are quicker than this delay.")
            GridRow {
              Toggle(isOn: $enableInlineTextCorrections) {
                Text("Enable inline text corrections")
              }.padding(.vertical)
            }.gridCellColumns(3)
            GridRow {
              Toggle(isOn: $enableInlineTextPredictions) {
                Text("Enable inline text predictions")
              }.padding(.vertical)
            }.gridCellColumns(3)
          }
        }
        Section(header: Text("Display")) {
          Grid(
            alignment: .leading,
            horizontalSpacing: 10,
            verticalSpacing: 5
          ) {
            FormSliderRow(
              text: "Font Size:", value: $fontSize, range: 12...36, step: 1,
              formatter: FormSliderRow.intFormatter
            )
            FormSliderRow(
              text: "Screen sleep delay in minutes:", value: $screenLockMinutes, range: 0...45,
              step: 5,
              helpMessage:
                "Keep the device awake for at least some number of minutes after the last application activity.",
              formatter: FormSliderRow.intFormatter
            )
          }
        }
        Section(header: Text("Help & Support")) {
          Button("Open Help") {
            let url = URL(string: "https://lazybearlabs.com/apps/mavis-aac/ios/help.html")!
            UIApplication.shared.open(url)
          }
          EmailSupportButton()
        }
        Section(header: Text("Configuration")) {
          NavigationLink(
            destination: {
              EditorView(
                file: MVFileManager.shared.getFileStore(
                  forUrl: MVFileManager.shared.phrases))

            },
            label: {
              // For some reason the default style does not seem to indicate navigation.
              Text("Edit Phrases…").foregroundStyle(.blue)
            })
          NavigationLink(
            destination: {
              EditorView(
                file: MVFileManager.shared.getFileStore(
                  forUrl: MVFileManager.shared.pronunciations))

            },
            label: {
              // For some reason the default style does not seem to indicate navigation.
              Text("Edit Pronunciations…").foregroundStyle(.blue)
            })
          Button("Show Soundbites…") {
            openSoundbites()
          }
          Button("Import File…") {
            showDocumentPicker.toggle()
          }
        }
        Section(header: Text("Export")) {
          Button("Export Logs…") {
            shareFile = ShareFile(fileURL: MVFileManager.shared.log)
          }
        }
      }
    }
    .navigationTitle("Prefs")
    .navigationDestination(for: FileStore.self) { file in
      EditorView(file: file)
    }
    .sheet(item: $shareFile) { shareFile in
      ActivityView(fileURL: shareFile.fileURL)
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
}

extension AVSpeechSynthesisVoice: Identifiable {
  public var id: String {
    self.identifier
  }
}

struct FormSliderRow: View {
  @State var text: String
  @Binding var value: Double
  @State var range: ClosedRange<Double>
  var step: Double?
  var helpMessage: String = ""
  var formatter: NumberFormatter = floatFormatter

  static var floatFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter
  }

  static var intFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.formatWidth = 2
    formatter.maximumFractionDigits = 0
    formatter.minimumFractionDigits = 0
    return formatter
  }

  var body: some View {
    GridRow {
      Text(text).gridColumnAlignment(.trailing)
      if let step = step {
        Slider(value: $value, in: range, step: step).padding().gridColumnAlignment(.center)
      } else {
        Slider(value: $value, in: range).padding().gridColumnAlignment(.center)
      }
      Text("\(formatter.string(for: $value.wrappedValue) ?? "0.0")").gridColumnAlignment(
        .trailing)
    }
    // FIXME: this clause makes the log report this error:
    // "Multiple alignments specified for grid column 0
    if helpMessage != "" {
      GridRow {
        Text(helpMessage).font(.caption)
          .gridColumnAlignment(.leading)
      }.gridCellColumns(3).gridColumnAlignment(.leading)
    }
  }
}

func openSoundbites() {
  let fileURL = MVFileManager.shared.soundsbites
  // Ensure the file exists (create it if needed for testing)
  if !FileManager.default.fileExists(atPath: fileURL.path) {
    // Try to create a directory if there isn't one, but not much to do
    // if this fails.
    try? FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: false)
  }
  // Open in Files app using shareddocuments:// scheme
  if let filesURL = URL(string: "shareddocuments://\(fileURL.path)") {
    UIApplication.shared.open(filesURL)
  }
}

#Preview {
  PrefsView()
}
