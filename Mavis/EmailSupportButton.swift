import SwiftUI
import MessageUI

let supportEmail = "support@lazybearlabs.com"

struct EmailSupportButton: View {
    @State private var showingMailView = false
    @State private var showingAlert = false

    var body: some View {
        Button("Contact Support") {
            if MFMailComposeViewController.canSendMail() {
                showingMailView = true
            } else {
                showingAlert = true
            }
        }
        .sheet(isPresented: $showingMailView) {
            MailView(
                recipient: supportEmail,
                subject: "Support for Mavis AAC"
            )
        }
        .sheet( isPresented: $showingAlert) {
          VStack{
            Text("Email Not Available").font(.headline)
            .padding()
            Text("Please email \(supportEmail) for assistance.").font(.body)
            .padding()
            Divider().padding()
            Button("OK", role: .cancel) {
              showingAlert = false
            }

          }
          .interactiveDismissDisabled(true)
          .presentationDetents([.fraction(0.3)])
        }
    }
}

struct MailView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.setToRecipients([recipient])
        composer.setSubject(subject)
        composer.mailComposeDelegate = context.coordinator
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailView

        init(_ parent: MailView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}
