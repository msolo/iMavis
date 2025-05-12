import Combine
import CoreData
import SwiftUI

struct ListView: View {
  @Binding var messages: [Message]
  @Binding var selection: Message?

  let saveAction: () -> Void

  var body: some View {
    GeometryReader { geometry in
      ScrollViewReader { scrollView in
        List(selection: $selection) {
          ForEach(messages) { row in
            Text(row.message)
              .tag(row)
              .listRowBackground(selection == row ? Color(.systemFill) : Color(.systemBackground))
          }
          .onDelete(perform: deleteItems)
        }
        .onAppear {
          scrollToBottom(scrollView)
        }
        .onChange(of: messages) {
          withAnimation {
            scrollToBottom(scrollView)
          }
        }
        .onChange(of: geometry.size) {
          // FIXME: This defer is obviously garbage, but without it
          // there are number of times that items are left hidden after
          // the keyboard or itemAccessoryView show up.
          scrollToBottom(scrollView)
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.750) {
            scrollToBottom(scrollView)
          }
        }
        .scrollContentBackground(.hidden)
      }
    }
  }

  private func scrollToBottom(_ scrollView: ScrollViewProxy) {
    if messages.count > 0 {
      scrollView.scrollTo(messages[messages.count - 1].id, anchor: .bottom)
    }
  }

  private func deleteItems(offsets: IndexSet) {
    withAnimation {
      messages.remove(atOffsets: offsets)
      saveAction()
    }
  }
}
