import AVFoundation
import Combine
import SwiftUI

struct EditorView: View {
  // Normally passing in a @State var seems like a no-no, but this
  // file only lasts as long as the view.
  @State var file: FileStore

  let detector = PassthroughSubject<Void, Never>()
  let publisher: AnyPublisher<Void, Never>

  init(file: FileStore) {
    self.file = file
    file.load()
    publisher =
      detector
      .debounce(for: .seconds(3), scheduler: DispatchQueue.main)
      .eraseToAnyPublisher()
  }

  func save() {
    // FIXME: Add a validate function so we don't save garbage.
    file.save()
  }

  // https://stackoverflow.com/questions/65966534/swiftui-texteditor-save-the-state-after-completion-of-editing
  var body: some View {
    Section(header: Text(file.name)) {
      TextEditor(text: $file.contents)
        .onChange(of: file.contents) {
          detector.send()
        }
        .onReceive(publisher) {
          // Save after some seconds.
          save()
        }
    }
    .padding()
    .onDisappear {
      save()
    }
    .navigationTitle("Editor")
  }
}

#Preview {
  struct Preview: View {
    @State var ptext = "preview"
    @State var pfile = FileStore(url: URL(fileURLWithPath: "/tmp/test.txt"))
    var body: some View {
      EditorView(
        file: pfile
      )
    }
  }
  return Preview()
}
