import SwiftData
import SwiftUI

struct UrgeFlowView: View {
    var metrics: [Metric]
    var preferredID: UUID?
    var onClose: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [MetricEntry]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.persist) private var persist
    @State private var model: UrgeViewModel?
    @State private var rideSheet: RideSheet?
    @State private var closeAfterSlip = false
    @State private var afterClose: AfterClose?
    @State private var keepJournalAfterDialog: Bool?
    @State private var askClose = false
    @State private var askSaveJournal = false
    @State private var pendingFinish: RideFinish?
    @State private var keepJournalForFinish = false
    @State private var focusedReasonID: UUID?
    @State private var newWhyText = ""
    @State private var newInsteadText = ""
    @State private var timerPinned = false
    @FocusState private var journalFocused: Bool
    @FocusState private var whyFocused: Bool
    @FocusState private var insteadFocused: Bool

    private static let topID = "urge.top"
    private static let confirmID = "urge.journalConfirm"

    private enum RideFinish {
        case slipped
        case notSure
    }

    private enum RideSheet: Identifiable {
        case surfing
        case slip

        var id: String {
            switch self {
            case .surfing: "surfing"
            case .slip: "slip"
            }
        }
    }

    private enum AfterClose {
        case passed
        case finish(RideFinish)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    ScrollViewReader { proxy in
                        ScrollView {
                            ReadableColumn {
                                content(model)
                            }
                            .padding(.vertical, Spacing.l)
                            .id(Self.topID)
                        }
                        .scrollContentBackground(.hidden)
                        .scrollDismissesKeyboard(.interactively)
                        .safeAreaInset(edge: .bottom) {
                            if model.step == .ride, pendingFinish == nil,
                               !AdaptiveLayout.isShortHeight(vertical: verticalSizeClass) {
                                ReadableColumn { rideActions(model) }
                                    .padding(.vertical, Spacing.s)
                                    .background(Color.tbCalm.opacity(0.95).ignoresSafeArea(edges: .bottom))
                            }
                        }
                        .onChange(of: model.step) { _, _ in
                            proxy.scrollTo(Self.topID, anchor: .top)
                        }
                        .onChange(of: pendingFinish) { _, finish in
                            revealConfirm(finish, proxy)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.tbCalm)
            .padding(.top, 44 + Spacing.m)
            .overlay(alignment: .top) {
                ZStack {
                    if timerPinned, model?.step == .ride {
                        pinnedTimer
                    }
                    UrgeCloseBar { closeButton }
                }
                .padding(.horizontal, Spacing.l)
                .padding(.top, Spacing.xs)
            }
            .background {
                ZStack {
                    Color.tbCalm
                    if model?.step == .ride, !reduceMotion {
                        RideAtmosphere()
                    }
                }
                .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog(RecoveryCopy.howDidItGo, isPresented: $askClose, titleVisibility: .visible) {
                Button(RecoveryCopy.theUrgePassed) { afterClose = .passed }
                Button(slipTitle) { afterClose = .finish(.slipped) }
                Button(RecoveryCopy.notSure) { afterClose = .finish(.notSure) }
                Button(RecoveryCopy.close, role: .cancel) {}
            }
            .confirmationDialog(RecoveryCopy.saveThisNote, isPresented: $askSaveJournal, titleVisibility: .visible) {
                Button(RecoveryCopy.saveIt) { keepJournalAfterDialog = true }
                Button(RecoveryCopy.deleteIt) { keepJournalAfterDialog = false }
                Button(RecoveryCopy.close, role: .cancel) {}
            } message: {
                Text(RecoveryCopy.saveThisNoteMessage)
            }
            .sheet(item: $rideSheet, onDismiss: {
                guard closeAfterSlip else { return }
                closeAfterSlip = false
                onClose()
            }) { sheet in
                switch sheet {
                case .surfing:
                    UrgeSurfingSheet()
                case .slip:
                    if let metric = selectedMetric {
                        SlipFlowView(metric: metric, prefilledTriggers: Array(model?.triggers ?? [])) {
                            let saved = persist("urge slipped", { try model?.markSlipped(now: Date(), keepJournal: keepJournalForFinish) }) != nil
                            if saved { closeAfterSlip = true }
                            rideSheet = nil
                        }
                        .persistFailureAlert()
                    } else {
                        EmptyView()
                    }
                }
            }
        }
        .onChange(of: askClose) { _, open in
            guard !open else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(50))
                guard let next = afterClose else { return }
                afterClose = nil
                PresentationSequence.afterDismiss {
                    switch next {
                    case .passed:
                        releaseTyping()
                        persist("urge passed") { try model?.passed(now: Date()) }
                    case .finish(let finish):
                        beginFinish(finish)
                    }
                }
            }
        }
        .onChange(of: askSaveJournal) { _, open in
            guard !open else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(50))
                guard let keep = keepJournalAfterDialog else { return }
                keepJournalAfterDialog = nil
                PresentationSequence.afterDismiss { commitPassed(keep: keep) }
            }
        }
        .background(Color.tbCalm.ignoresSafeArea())
        .onAppear { prepare() }
        .onChange(of: metrics.count) {
            guard LaunchConfiguration.opensUrgeRide, model?.step == .empty else { return }
            prepare()
        }
        .onChange(of: model?.step) { _, step in
            guard step != .ride else { return }
            newWhyText = ""
            newInsteadText = ""
            timerPinned = false
            whyFocused = false
            insteadFocused = false
        }
        .onChange(of: model?.selectedID) { _, _ in
            focusedReasonID = sortedReasons.first?.id
        }
    }

    private var closeButton: some View {
        Button(action: closeTapped) {
            Text(RecoveryCopy.close)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.tbOnCalm)
                .padding(.horizontal, Spacing.l)
                .frame(minHeight: 44)
                .background(Color.tbOnCalm.opacity(0.14), in: Capsule())
                .background(Color.tbCalm, in: Capsule())
                .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilitySortPriority(1)
    }

    private func closeTapped() {
        releaseTyping()
        if model?.step == .ride {
            askClose = true
        } else if model?.step == .passed {
            leavePassed()
        } else {
            onClose()
        }
    }

    @ViewBuilder
    private func content(_ model: UrgeViewModel) -> some View {
        switch model.step {
        case .empty:
            Text(RecoveryCopy.noViceForUrge)
                .font(.title2)
                .foregroundStyle(Color.tbOnCalm)
        case .choose:
            VStack(alignment: .leading, spacing: Spacing.m) {
                Text(RecoveryCopy.whichOne)
                    .font(.title2)
                    .foregroundStyle(Color.tbOnCalm)
                ForEach(model.vices) { metric in
                    calmChoice(metric.name) { model.choose(metric.id) }
                }
            }
        case .intensity:
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(RecoveryCopy.howStrong)
                    .font(.title2)
                    .foregroundStyle(Color.tbOnCalm)
                    .padding(.bottom, Spacing.s)
                ForEach(1...5, id: \.self) { level in
                    Button(RecoveryCopy.intensityLabel(level)) {
                        model.intensity = level
                        persist("start urge") { try model.begin(metrics: metrics, now: Date()) }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .padding(.horizontal, Spacing.l)
                    .background(Color.tbOnCalm.opacity(model.intensity == level ? 0.2 : 0.12), in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                    .foregroundStyle(Color.tbOnCalm)
                    .accessibilityIdentifier(AccessibilityIdentifiers.urgeIntensity(level))
                }
                Button(RecoveryCopy.skip) {
                    model.intensity = 3
                    persist("start urge") { try model.begin(metrics: metrics, now: Date()) }
                }
                .frame(minHeight: 44)
                .foregroundStyle(Color.tbOnCalm)
                surfingLink()
            }
        case .ride:
            rideBody(model)
        case .passed:
            passed(model)
        case .unsure:
            EmptyView()
        }
    }

    private func surfingLink(inCard: Bool = false) -> some View {
        Button {
            PresentationSequence.resignKeyboardThen { rideSheet = .surfing }
        } label: {
            HStack(spacing: Spacing.s) {
                Text(RecoveryCopy.whatIsUrgeSurfing)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: Spacing.s)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Color.tbOnCalm)
            .padding(.horizontal, inCard ? 0 : Spacing.l)
            .padding(.vertical, inCard ? Spacing.xs : 0)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                if !inCard {
                    RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                        .fill(Color.tbOnCalm.opacity(0.12))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityIdentifiers.urgeSurfingLearn)
    }

    private func calmChoice(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.tbOnCalm)
                .frame(maxWidth: .infinity, minHeight: 52)
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.s)
                .background(Color.tbOnCalm.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    /// One tree for portrait and landscape so rotation does not swap ScrollViews (white flash).
    @ViewBuilder
    private func rideBody(_ model: UrgeViewModel) -> some View {
        Group {
        if AdaptiveLayout.isShortHeight(vertical: verticalSizeClass) {
            HStack(alignment: .top, spacing: Spacing.l) {
                VStack(spacing: Spacing.m) {
                    rideFocus(model)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                VStack(alignment: .leading, spacing: Spacing.l) {
                    rideSupport(model)
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        } else {
            VStack(spacing: Spacing.l) {
                rideFocus(model)
                rideSupport(model)
            }
        }
        }
        .animation(nil, value: verticalSizeClass)
    }

    @ViewBuilder
    private func rideFocus(_ model: UrgeViewModel) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = model.remaining(at: context.date)
            VStack(spacing: Spacing.m) {
                BreathingCircle(
                    maxDiameter: AdaptiveLayout.breathingDiameter(vertical: verticalSizeClass),
                    progress: model.progress(at: context.date)
                )
                VStack(spacing: Spacing.s) {
                    countdownLabel(remaining, font: .system(.largeTitle, design: .rounded).weight(.bold))
                        .onScrollVisibilityChange(threshold: 0.5) { visible in
                            timerPinned = !visible
                        }
                    if remaining == 0 {
                        Text(RecoveryCopy.stillWithIt)
                            .font(.body)
                            .foregroundStyle(Color.tbOnCalm)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                }
                addFiveButton(model)
            }
            .onChange(of: remaining == 0) { _, done in
                if done { UrgeTimerChime.play() }
            }
            .sensoryFeedback(.success, trigger: remaining == 0) { _, done in done }
        }
    }

    private var pinnedTimer: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = model?.remaining(at: context.date) ?? 0
            countdownLabel(remaining, font: .system(.title3, design: .rounded).weight(.bold))
                .padding(.horizontal, Spacing.m)
                .frame(minHeight: 44)
                .accessibilityLabel(clock(remaining))
        }
        .allowsHitTesting(false)
    }

    private func addFiveButton(_ model: UrgeViewModel) -> some View {
        Button { model.addFiveMinutes(now: Date()) } label: {
            Text(RecoveryCopy.addFiveMinutes)
                .font(.headline)
                .foregroundStyle(Color.tbOnCalm)
                .padding(.horizontal, Spacing.l)
                .frame(minWidth: 120, minHeight: 44)
                .background(Color.tbOnCalm.opacity(0.14), in: Capsule())
                .overlay {
                    Capsule().strokeBorder(Color.tbOnCalm.opacity(0.55), lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func rideSupport(_ model: UrgeViewModel) -> some View {
        if let pendingFinish {
            journalConfirm(pendingFinish, model)
        } else {
            VStack(alignment: .leading, spacing: Spacing.m) {
                Text(RecoveryCopy.urgeIntro)
                    .font(.body)
                    .foregroundStyle(Color.tbOnCalm)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                surfingLink(inCard: true)
            }
            .padding(Spacing.l)
            .background(Color.tbOnCalm.opacity(0.1), in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            journalEditor(model)
            if let plan = selectedMetric?.ifThenPlan, !plan.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(RecoveryCopy.yourPlanPrefix).font(.headline)
                    Text(plan).font(.body)
                }
                .foregroundStyle(Color.tbOnCalm)
                .padding(Spacing.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.tbOnCalm.opacity(0.1), in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            }
            whySection(showAddField: true)
            habitChips
            if AdaptiveLayout.isShortHeight(vertical: verticalSizeClass) {
                rideActions(model)
            }
        }
    }

    private func rideActions(_ model: UrgeViewModel) -> some View {
        VStack(spacing: Spacing.s) {
            PrimaryButton(title: RecoveryCopy.theUrgePassed, systemImage: nil, accessibilityID: AccessibilityIdentifiers.urgePassed) {
                journalFocused = false
                whyFocused = false
                persist("urge passed") { try model.passed(now: Date()) }
            }
            Button { beginFinish(.slipped) } label: {
                Text(slipTitle)
                    .font(.headline)
                    .foregroundStyle(Color.tbOnCalm)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .padding(.horizontal, Spacing.l)
                    .background(Color.tbOnCalm.opacity(0.14), in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                            .strokeBorder(Color.tbOnCalm.opacity(0.45), lineWidth: 1.5)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityIdentifiers.urgeSlipped)
        }
    }

    private func journalEditor(_ model: UrgeViewModel, hint: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(RecoveryCopy.writeItDown)
                .font(.headline)
                .foregroundStyle(Color.tbOnCalm)
            if hint {
                Text(RecoveryCopy.writeItDownHint)
                    .font(.subheadline)
                    .foregroundStyle(Color.tbOnCalm.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            TextField(
                "",
                text: Bindable(model).journalText,
                prompt: Text(RecoveryCopy.journalPlaceholder).foregroundStyle(Color.tbOnCalm.opacity(0.55)),
                axis: .vertical
            )
            .lineLimit(3...8)
            .textFieldStyle(.plain)
            .focused($journalFocused)
            .padding(Spacing.m)
            .background(Color.tbOnCalm.opacity(0.16), in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .foregroundStyle(Color.tbOnCalm)
            .tint(Color.tbOnCalm)
            .accessibilityIdentifier(AccessibilityIdentifiers.urgeJournal)
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tbOnCalm.opacity(0.1), in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private func journalConfirm(_ finish: RideFinish, _ model: UrgeViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(RecoveryCopy.saveThisNote)
                .font(.title2)
                .foregroundStyle(Color.tbOnCalm)
            Text(RecoveryCopy.saveThisNoteMessage)
                .font(.body)
                .foregroundStyle(Color.tbOnCalm.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Text(model.journalText)
                .font(.body)
                .foregroundStyle(Color.tbOnCalm)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.m)
                .background(Color.tbOnCalm.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            PrimaryButton(title: RecoveryCopy.saveIt, systemImage: nil, accessibilityID: AccessibilityIdentifiers.urgeJournalSave) {
                complete(finish, keep: true)
            }
            Button(RecoveryCopy.deleteIt) { complete(finish, keep: false) }
                .frame(minHeight: 44)
                .foregroundStyle(Color.tbOnCalm)
                .accessibilityIdentifier(AccessibilityIdentifiers.urgeJournalDelete)
            Button(RecoveryCopy.back) { pendingFinish = nil }
                .frame(minHeight: 44)
                .foregroundStyle(Color.tbOnCalm)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .id(Self.confirmID)
    }

    private func revealConfirm(_ finish: RideFinish?, _ proxy: ScrollViewProxy) {
        guard finish != nil else { return }
        withAnimation(UrgeBuddyMotion.animation(UrgeBuddyMotion.spring, reduceMotion: reduceMotion)) {
            proxy.scrollTo(Self.confirmID, anchor: .top)
        }
    }

    private func passed(_ model: UrgeViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text(RecoveryCopy.urgePassed(model.beaten))
                .font(.title2)
                .foregroundStyle(Color.tbOnCalm)
            Text(RecoveryCopy.urgeSurfedIt)
                .font(.body)
                .foregroundStyle(Color.tbOnCalm)
                .fixedSize(horizontal: false, vertical: true)
            if model.hasJournal {
                journalEditor(model, hint: false)
                journalChoice(model)
            }
            if !sortedReasons.isEmpty {
                whySection(showAddField: false)
            }
            Text(RecoveryCopy.whatSetItOff)
                .font(.headline)
                .foregroundStyle(Color.tbOnCalm)
            triggerGrid
            PrimaryButton(title: RecoveryCopy.done, systemImage: nil, accessibilityID: AccessibilityIdentifiers.urgeDone, action: leavePassed)
        }
    }

    private func journalChoice(_ model: UrgeViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(RecoveryCopy.saveThisNote)
                .font(.headline)
                .foregroundStyle(Color.tbOnCalm)
            Text(RecoveryCopy.saveThisNoteMessage)
                .font(.subheadline)
                .foregroundStyle(Color.tbOnCalm.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            choiceButton(RecoveryCopy.saveIt, selected: model.journalChoice == .save, id: AccessibilityIdentifiers.urgeJournalSave) {
                model.journalChoice = .save
            }
            choiceButton(RecoveryCopy.deleteIt, selected: model.journalChoice == .discard, id: AccessibilityIdentifiers.urgeJournalDelete) {
                model.journalChoice = .discard
            }
        }
    }

    private func choiceButton(_ title: String, selected: Bool, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label {
                Text(title)
            } icon: {
                if selected {
                    Image(systemName: "checkmark")
                }
            }
            .font(.headline)
            .foregroundStyle(Color.tbOnCalm)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, Spacing.l)
            .background(
                Color.tbOnCalm.opacity(selected ? 0.28 : 0.12),
                in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityRemoveTraits(selected ? [] : .isSelected)
    }

    @ViewBuilder
    private func whySection(showAddField: Bool) -> some View {
        let reasons = sortedReasons
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(RecoveryCopy.yourWhy)
                .font(.headline)
                .foregroundStyle(Color.tbOnCalm)
            if reasons.isEmpty {
                Text(RecoveryCopy.noReasonsYet)
                    .font(.subheadline)
                    .foregroundStyle(Color.tbOnCalm.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            } else if reduceMotion || reasons.count == 1 {
                ForEach(reasons) { reason in
                    reasonQuote(reason.text)
                }
            } else {
                whyPager(reasons)
            }
            if showAddField, selectedMetric != nil {
                addWhyField
            }
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tbOnCalm.opacity(0.1), in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .onChange(of: reasons.map(\.id)) { _, ids in
            syncFocusedReason(with: ids)
        }
        .onAppear {
            syncFocusedReason(with: reasons.map(\.id))
        }
    }

    @ViewBuilder
    private func whyPager(_ reasons: [Reason]) -> some View {
        let page = focusedReasonPage(in: reasons)
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(RecoveryCopy.swipeYourWhys)
                    .font(.subheadline)
                    .foregroundStyle(Color.tbOnCalm.opacity(0.85))
                Spacer(minLength: Spacing.s)
                if let page {
                    Text(RecoveryCopy.whyPageIndicator(current: page, total: reasons.count))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.tbOnCalm.opacity(0.85))
                        .monospacedDigit()
                        .accessibilityHidden(true)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(reasons) { reason in
                        reasonQuote(reason.text)
                            .padding(.horizontal, Spacing.xs)
                            .containerRelativeFrame(.horizontal, alignment: .leading)
                            .id(reason.id)
                            .accessibilityLabel(
                                pageLabel(for: reason, in: reasons)
                            )
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 0, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollPosition(id: $focusedReasonID, anchor: .leading)
            .accessibilityIdentifier(AccessibilityIdentifiers.urgeWhyPager)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(
                page.map { RecoveryCopy.whyPageIndicator(current: $0, total: reasons.count) } ?? RecoveryCopy.yourWhy
            )
        }
    }

    private func reasonQuote(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            Image(systemName: "quote.opening")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.tbOnCalm.opacity(0.55))
                .accessibilityHidden(true)
            Text(text)
                .font(.title3)
                .foregroundStyle(Color.tbOnCalm)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func focusedReasonPage(in reasons: [Reason]) -> Int? {
        guard let focusedReasonID,
              let index = reasons.firstIndex(where: { $0.id == focusedReasonID }) else { return nil }
        return index + 1
    }

    private func pageLabel(for reason: Reason, in reasons: [Reason]) -> String {
        let index = (reasons.firstIndex(where: { $0.id == reason.id }) ?? 0) + 1
        return "\(RecoveryCopy.whyPageIndicator(current: index, total: reasons.count)). \(reason.text)"
    }

    private func syncFocusedReason(with ids: [UUID]) {
        guard !ids.isEmpty else {
            focusedReasonID = nil
            return
        }
        if let focusedReasonID, ids.contains(focusedReasonID) { return }
        focusedReasonID = ids.first
    }

    private var addWhyField: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            TextField(
                "",
                text: $newWhyText,
                prompt: Text(RecoveryCopy.addReason).foregroundStyle(Color.tbOnCalm.opacity(0.55)),
                axis: .vertical
            )
            .lineLimit(1...3)
            .textFieldStyle(.plain)
            .focused($whyFocused)
            .padding(Spacing.m)
            .background(Color.tbOnCalm.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .foregroundStyle(Color.tbOnCalm)
            .tint(Color.tbOnCalm)
            .accessibilityIdentifier(AccessibilityIdentifiers.urgeAddWhy)
            .submitLabel(.done)
            .onSubmit { addWhy() }
            Button(RecoveryCopy.saveReason) { addWhy() }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityIdentifier(AccessibilityIdentifiers.urgeSaveWhy)
                .foregroundStyle(Color.tbOnCalm)
                .background(
                    Color.tbOnCalm.opacity(newWhyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.08 : 0.16),
                    in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                )
                .disabled(newWhyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func addWhy() {
        guard let metric = selectedMetric else { return }
        let text = newWhyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard persist("add reason", { try RecoveryStore(context: modelContext).addReason(text, to: metric) }) != nil else { return }
        newWhyText = ""
        whyFocused = false
        if let id = model?.selectedID,
           let last = (try? RecoveryStore(context: modelContext).reasons(for: id))?
            .sorted(by: { $0.sortOrder < $1.sortOrder })
            .last {
            focusedReasonID = last.id
        }
    }

    private var habitChips: some View {
        let habits = metrics.filter { $0.habitType == .positive && !$0.isArchived }
        return VStack(alignment: .leading, spacing: Spacing.s) {
            Text(RecoveryCopy.tryOneInstead)
                .font(.headline)
                .foregroundStyle(Color.tbOnCalm)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(habits) { habit in
                insteadRow(habit)
            }
            addInsteadField
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tbOnCalm.opacity(0.1), in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private func insteadRow(_ habit: Metric) -> some View {
        let done = habitDoneToday(habit.id)
        return Button {
            persist("habit done") {
                try RecoveryStore(context: modelContext).setHabitDone(habit, on: Date(), done: !done, now: Date())
            }
        } label: {
            HStack(spacing: Spacing.m) {
                Image(systemName: habit.iconName)
                    .font(.body.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .background(Color.tbOnCalm.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityHidden(true)
                Text(habit.name)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Color.tbOnCalm.opacity(done ? 1 : 0.92))
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(done ? "\(habit.name), done" : habit.name)
        .sensoryFeedback(done ? .success : .selection, trigger: done)
    }

    private func habitDoneToday(_ id: UUID) -> Bool {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return false }
        return entries.contains {
            $0.metricID == id && $0.day >= start && $0.day < end && $0.status == .done
        }
    }

    private var insteadTextIsEmpty: Bool {
        newInsteadText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var addInsteadField: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            TextField(
                "",
                text: $newInsteadText,
                prompt: Text(RecoveryCopy.addInstead).foregroundStyle(Color.tbOnCalm.opacity(0.55)),
                axis: .vertical
            )
            .lineLimit(1...3)
            .textFieldStyle(.plain)
            .focused($insteadFocused)
            .padding(Spacing.m)
            .background(Color.tbOnCalm.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .foregroundStyle(Color.tbOnCalm)
            .tint(Color.tbOnCalm)
            .accessibilityIdentifier(AccessibilityIdentifiers.urgeAddInstead)
            .submitLabel(.done)
            .onSubmit { addInstead() }
            Button(RecoveryCopy.saveInstead) { addInstead() }
                .buttonStyle(.plain)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityIdentifier(AccessibilityIdentifiers.urgeSaveInstead)
                .foregroundStyle(Color.tbOnCalm)
                .background(
                    Color.tbOnCalm.opacity(insteadTextIsEmpty ? 0.08 : 0.16),
                    in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                )
                .disabled(insteadTextIsEmpty)
        }
    }

    private func addInstead() {
        let text = newInsteadText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let alreadyThere = metrics.contains {
            $0.habitType == .positive && !$0.isArchived && $0.name.localizedCaseInsensitiveCompare(text) == .orderedSame
        }
        if alreadyThere {
            newInsteadText = ""
            insteadFocused = false
            return
        }
        guard persist("add instead", {
            try RecoveryStore(context: modelContext).addMetric(
                name: text,
                habitType: .positive,
                iconName: Presets.iconName(matching: text),
                startedAt: Date(),
                costPerDay: nil,
                firstReason: nil
            )
        }) != nil else { return }
        newInsteadText = ""
        insteadFocused = false
    }

    private var triggerGrid: some View {
        let binding = Binding<Set<String>>(
            get: { Set((model?.triggers ?? []).map(\.rawValue)) },
            set: { raw in model?.triggers = Set(raw.compactMap(TriggerTag.init(rawValue:))) }
        )
        return ChipGrid(
            items: TriggerTag.allCases.map { ChipOption(id: $0.rawValue, title: $0.title, systemImage: $0.systemImage) },
            selection: binding
        )
    }

    private var selectedMetric: Metric? {
        metrics.first { $0.id == model?.selectedID }
    }

    private var slipTitle: String {
        selectedMetric?.isCuttingBack == true ? RecoveryCopy.iHadOne : RecoveryCopy.iSlipped
    }

    private func beginFinish(_ finish: RideFinish) {
        releaseTyping()
        if model?.hasJournal == true {
            pendingFinish = finish
        } else {
            complete(finish, keep: false)
        }
    }

    private func complete(_ finish: RideFinish, keep: Bool) {
        pendingFinish = nil
        keepJournalForFinish = keep
        switch finish {
        case .slipped:
            slipped()
        case .notSure:
            guard persist("urge not sure", { try model?.markNotSure(now: Date(), keepJournal: keep) }) != nil else { return }
            onClose()
        }
    }

    private func leavePassed() {
        guard let model else {
            onClose()
            return
        }
        if model.needsJournalChoice {
            askSaveJournal = true
            return
        }
        guard persist("urge reflection", { try model.commitReflection(keepJournal: model.journalChoice == .save) }) != nil else { return }
        onClose()
    }

    private func commitPassed(keep: Bool) {
        model?.journalChoice = keep ? .save : .discard
        guard persist("urge reflection", { try model?.commitReflection(keepJournal: keep) }) != nil else { return }
        onClose()
    }

    /// Quit opens the slip flow. Cut back logs one more for today and closes.
    private func releaseTyping() {
        journalFocused = false
        whyFocused = false
        insteadFocused = false
    }

    private func slipped() {
        guard let metric = selectedMetric, metric.isCuttingBack else {
            PresentationSequence.resignKeyboardThen { rideSheet = .slip }
            return
        }
        guard persist("cut-back slip", { () throws -> Void in
            try RecoveryStore(context: modelContext).addAmount(metric, 1, on: Date(), now: Date())
            try model?.markSlipped(now: Date(), keepJournal: keepJournalForFinish)
        }) != nil else { return }
        onClose()
    }

    private var sortedReasons: [Reason] {
        guard let id = model?.selectedID else { return [] }
        let store = RecoveryStore(context: modelContext)
        return (try? store.reasons(for: id).sorted { $0.sortOrder < $1.sortOrder }) ?? []
    }

    private func prepare() {
        if model == nil {
            model = UrgeViewModel(store: RecoveryStore(context: modelContext))
        }
        model?.start(metrics: metrics, preferredID: preferredID, now: Date())
    }

    @ViewBuilder
    private func countdownLabel(_ remaining: TimeInterval, font: Font) -> some View {
        let label = Text(clock(remaining))
            .font(font)
            .monospacedDigit()
            .foregroundStyle(Color.tbOnCalm)
        if LaunchConfiguration.capturesStillFrames {
            label
        } else {
            label
                .contentTransition(.numericText(countsDown: true))
                .urgeBuddyAnimation(UrgeBuddyMotion.quick, value: Int(remaining), reduceMotion: reduceMotion)
        }
    }

    private func clock(_ remaining: TimeInterval) -> String {
        let total = Int(remaining)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

/// Close sits on the leading edge on iPhone. On iPhone Duo it follows the vertical bar so it stays on the thumb side.
private struct UrgeCloseBar<Label: View>: View {
    @ViewBuilder var label: () -> Label

    var body: some View {
        if #available(iOS 27.1, *) {
            UrgeCloseBarOn27(label: label)
        } else {
            UrgeCloseBarLayout(onTrailingEdge: false, label: label)
        }
    }
}

@available(iOS 27.1, *)
private struct UrgeCloseBarOn27<Label: View>: View {
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
    @ViewBuilder var label: () -> Label

    var body: some View {
        UrgeCloseBarLayout(onTrailingEdge: toolbarVerticalEdge == .trailing, label: label)
    }
}

private struct UrgeCloseBarLayout<Label: View>: View {
    var onTrailingEdge: Bool
    @ViewBuilder var label: () -> Label

    var body: some View {
        HStack(spacing: 0) {
            if onTrailingEdge {
                Spacer(minLength: 0)
                label()
            } else {
                label()
                Spacer(minLength: 0)
            }
        }
    }
}
