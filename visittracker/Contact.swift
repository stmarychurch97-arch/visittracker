import SwiftUI
import MessageUI

enum Contact {
    static func clean(_ phone: String) -> String {
        phone.filter { $0.isNumber || $0 == "+" }
    }

    static func call(_ phone: String) {
        if let url = URL(string: "tel://\(clean(phone))") { UIApplication.shared.open(url) }
    }

    static func whatsapp(_ phone: String, text: String) {
        let num = phone.filter { $0.isNumber }
        let msg = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/\(num)?text=\(msg)") { UIApplication.shared.open(url) }
    }

    static func message(for p: Person) -> String {
        Settings.template.replacingOccurrences(of: "{name}", with: p.name)
    }
}

struct SMSView: UIViewControllerRepresentable {
    let recipient: String
    let body: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = [Contact.clean(recipient)]
        vc.body = body
        vc.messageComposeDelegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ vc: MFMessageComposeViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: SMSView
        init(_ p: SMSView) { parent = p }
        func messageComposeViewController(_ c: MFMessageComposeViewController,
                                          didFinishWith result: MessageComposeResult) {
            parent.dismiss()
        }
    }
}
