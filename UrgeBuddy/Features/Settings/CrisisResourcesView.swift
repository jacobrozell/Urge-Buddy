import SwiftUI

struct CrisisResourcesView: View {
    var body: some View {
        List {
            Section {
                Link(RecoveryCopy.crisisImmediate, destination: URL(string: "tel:911")!)
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text(RecoveryCopy.crisis988)
                        .font(.headline)
                    Link(RecoveryCopy.call988, destination: URL(string: "tel:988")!)
                    Link(RecoveryCopy.text988, destination: URL(string: "sms:988")!)
                }
                .padding(.vertical, Spacing.s)
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text(RecoveryCopy.crisisSAMHSA)
                        .font(.headline)
                    Text(RecoveryCopy.crisisSAMHSADetail)
                        .font(.subheadline)
                        .foregroundStyle(Color.tbTextSecondary)
                    Link(RecoveryCopy.callSAMHSA, destination: URL(string: "tel:18006624357")!)
                }
                .padding(.vertical, Spacing.s)
                Link(RecoveryCopy.crisisOutside, destination: AppLinks.crisisFindAHelpline)
            }
            Section {
                Text(RecoveryCopy.crisisMedical)
                    .font(.footnote)
                    .foregroundStyle(Color.tbTextSecondary)
            }
        }
        .readableListMargins()
        .navigationTitle(RecoveryCopy.getHelpNow)
        .navigationBarTitleDisplayMode(.inline)
    }
}
