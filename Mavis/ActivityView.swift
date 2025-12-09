import SwiftUI
import UIKit

// Used when sharing an export.zip file of the existing configuration files and logs.
struct ActivityView: UIViewControllerRepresentable {
  let fileURL: URL

  func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>)
    -> UIActivityViewController
  {
    return UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
  }

  func updateUIViewController(
    _ uiViewController: UIActivityViewController,
    context: UIViewControllerRepresentableContext<ActivityView>
  ) {}
}

struct ShareFile: Identifiable {
  let id = UUID()
  let fileURL: URL
}
