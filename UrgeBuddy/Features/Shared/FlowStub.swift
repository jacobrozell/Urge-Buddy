import SwiftUI

struct FlowStub: View {
    var title: String
    var message: String
    var dismiss: () -> Void

    var body: some View {
        NavigationStack {
            ReadableColumn {
                Text(message)
                    .font(.title2)
                    .foregroundStyle(Color.tbTextPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, Spacing.xl)
            }
            .background(Color.tbBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(RecoveryCopy.close, action: dismiss)
                }
            }
        }
    }
}
