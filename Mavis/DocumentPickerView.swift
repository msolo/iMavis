import Combine
import CoreData
import SwiftUI

struct DocumentPickerView: UIViewControllerRepresentable {
  @Binding var error: Error?

  class Coordinator: NSObject, UIDocumentPickerDelegate {
    var parent: DocumentPickerView

    init(parent: DocumentPickerView) {
      self.parent = parent
    }

    func documentPicker(
      _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]
    ) {
      for url in urls {
        do {
          try MVFileManager.shared.copyFileIntoDocs(fileURL: url)
        } catch {
          parent.error = error
          return
        }
      }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    }
  }

  func makeCoordinator() -> Coordinator {
    return Coordinator(parent: self)
  }

  func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
    let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [
      .plainText, .zip, .json,
    ])
    documentPicker.delegate = context.coordinator
    return documentPicker
  }

  func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context)
  {}
}
