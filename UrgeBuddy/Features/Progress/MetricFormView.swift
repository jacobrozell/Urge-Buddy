import SwiftData
import SwiftUI

struct MetricFormView: View {
    var metric: Metric?
    var habitType: HabitType = .vice

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.persist) private var persist
    @State private var model: MetricFormViewModel?
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                if let model {
                    TextField(RecoveryCopy.nameField, text: Bindable(model).name)
                    if let error = model.nameError, !model.name.isEmpty || !model.isNew {
                        Text(error).font(.footnote).foregroundStyle(Color.tbSlip)
                    }
                    if model.showsTypePicker {
                        Picker(RecoveryCopy.metricType, selection: Bindable(model).habitType) {
                            Text(RecoveryCopy.quitting).tag(HabitType.vice)
                            Text(RecoveryCopy.building).tag(HabitType.positive)
                        }
                    }
                    if model.showsModePicker {
                        Section {
                            Picker(RecoveryCopy.quitOrCutBack, selection: Bindable(model).viceMode) {
                                Text(RecoveryCopy.quitMode).tag(ViceMode.quit)
                                Text(RecoveryCopy.cutBackMode).tag(ViceMode.cutBack)
                            }
                            .pickerStyle(.segmented)
                        } footer: {
                            if model.isCuttingBack { Text(RecoveryCopy.cutBackExplainer) }
                        }
                    }
                    if model.habitType == .positive {
                        Section {
                            Toggle(RecoveryCopy.trackAnAmount, isOn: Bindable(model).tracksHabitAmount)
                        } footer: {
                            Text(RecoveryCopy.trackAnAmountFooter)
                        }
                    }
                    if model.showsAmountFields {
                        amountFields(model)
                    }
                    if model.showsQuitDate {
                        DatePicker(RecoveryCopy.quitDate, selection: Bindable(model).startedAt, in: ...Date(), displayedComponents: .date)
                    }
                    if model.showsCost {
                        TextField(model.costLabel, text: Bindable(model).costText)
                            .keyboardType(.decimalPad)
                    }
                    Section(RecoveryCopy.iconHeader) {
                        iconPicker(model)
                    }
                    if !model.isNew {
                        Section {
                            Toggle(RecoveryCopy.archive, isOn: Bindable(model).isArchived)
                            Button(RecoveryCopy.delete, role: .destructive) { confirmDelete = true }
                        }
                    }
                }
            }
            .tbNavigationBarBackground()
            .navigationTitle(model?.isNew == true ? RecoveryCopy.addSomething : RecoveryCopy.edit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(RecoveryCopy.close) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(RecoveryCopy.save) { save() }
                        .disabled(model?.canSave != true)
                }
            }
            .confirmationDialog(RecoveryCopy.deleteConfirm(metric?.name ?? ""), isPresented: $confirmDelete, titleVisibility: .visible) {
                Button(RecoveryCopy.delete, role: .destructive) { deleteMetric() }
                Button(RecoveryCopy.close, role: .cancel) {}
            }
        }
        .adaptiveFormSheet()
        .onAppear {
            if model == nil { model = MetricFormViewModel(metric: metric, habitType: habitType) }
        }
        .onChange(of: model?.viceMode) { old, new in
            if old == .cutBack, new == .quit { model?.startedAt = Date() }
        }
    }

    @ViewBuilder
    private func amountFields(_ model: MetricFormViewModel) -> some View {
        Section {
            LabeledContent(RecoveryCopy.unitField) {
                TextField(RecoveryCopy.unitPlaceholder, text: Bindable(model).unit)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.never)
            }
            LabeledContent(model.targetLabel) {
                TextField("0", text: Bindable(model).targetText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            }
            if model.isCuttingBack {
                LabeledContent(RecoveryCopy.usualPerDay) {
                    TextField(RecoveryCopy.optional, text: Bindable(model).baselineText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
        } footer: {
            if let error = model.targetError { Text(error).foregroundStyle(Color.tbSlip) }
        }
    }

    private func iconPicker(_ model: MetricFormViewModel) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: Spacing.s) {
            ForEach(model.icons, id: \.self) { icon in
                let selected = model.iconName == icon
                Button {
                    model.iconName = icon
                } label: {
                    Image(systemName: icon)
                        .frame(minWidth: 44, minHeight: 44)
                        .foregroundStyle(selected ? Color.tbOnBrand : Color.tbTextPrimary)
                        .background(selected ? Color.tbBrand : Color.tbSurfaceMuted, in: RoundedRectangle(cornerRadius: Radius.control))
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(RecoveryCopy.iconName(icon))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    private func save() {
        guard let model else { return }
        guard persist("save metric", { try model.save(metric: metric, store: RecoveryStore(context: modelContext), now: Date()) }) != nil else { return }
        if model.canSave { dismiss() }
    }

    private func deleteMetric() {
        guard let model, let metric else { return }
        guard persist("delete metric", { try model.delete(metric, store: RecoveryStore(context: modelContext)) }) != nil else { return }
        dismiss()
    }
}
