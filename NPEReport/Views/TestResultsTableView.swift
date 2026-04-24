import SwiftUI

struct TestResultsTableView: View {
    @Binding var testResults: [TestResult]
    let showValidationErrors: Bool

    @State private var newResult = TestResult.blank()
    @State private var newTestDate = Date()
    @State private var editingResult: TestResult?
    @State private var showEditModal = false
    @State private var showEntryValidationErrors = false

    private let brandYellow = Color.npBrandYellow

    private var canAddCircuit: Bool {
        currentCircuitValidationIssues.isEmpty
    }

    private var currentCircuitValidationIssues: [String] {
        var result = newResult
        result.testDate = Self.testDateFormatter.string(from: newTestDate)
        return result.missingRequiredFields
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            TestResultsSection(title: "Circuit Entry", brandYellow: brandYellow) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Add one circuit result at a time. Use the guided controls below to keep the PDF output consistent.")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    if showEntryValidationErrors, !currentCircuitValidationIssues.isEmpty {
                        ValidationNotice(
                            title: "Finish This Circuit Entry",
                            messages: currentCircuitValidationIssues.map { "\($0) is required." }
                        )
                    }

                    DatePicker("Test Date", selection: $newTestDate, displayedComponents: .date)

                    EntryTextField(
                        title: "Circuit / Equipment",
                        placeholder: "Lighting, GPO, A/C, Pump",
                        text: $newResult.circuitOrEquipment,
                        errorMessage: currentCircuitErrorMessage(for: "Circuit / Equipment")
                    )

                    VisualInspectionHelperField(
                        value: $newResult.visualInspection,
                        errorMessage: currentCircuitErrorMessage(for: "Visual Inspection")
                    )

                    IdentifierField(
                        title: "Circuit No.",
                        placeholder: "C1",
                        text: $newResult.circuitNo,
                        helperText: "Uppercase letters, numbers, spaces, dash and slash only.",
                        errorMessage: currentCircuitErrorMessage(for: "Circuit No.")
                    )

                    StructuredCableSizeField(
                        value: $newResult.cableSize,
                        errorMessage: currentCircuitErrorMessage(for: "Cable Size")
                    )

                    StructuredProtectionField(
                        value: $newResult.protectionSizeType,
                        errorMessage: currentCircuitErrorMessage(for: "Protection")
                    )

                    IdentifierField(
                        title: "Neutral No.",
                        placeholder: "N1",
                        text: $newResult.neutralNo,
                        helperText: "Uppercase letters, numbers, spaces, dash and slash only.",
                        errorMessage: currentCircuitErrorMessage(for: "Neutral No.")
                    )

                    EarthContinuityHelperField(
                        value: $newResult.earthContinuity,
                        errorMessage: currentCircuitErrorMessage(for: "Earth Continuity")
                    )

                    StructuredRCDField(
                        value: $newResult.rcd,
                        tripTimeMs: $newResult.rcdTripTimeMs,
                        protectionValue: $newResult.protectionSizeType,
                        errorMessage: currentCircuitErrorMessage(for: "RCD")
                    )

                    InsulationResistanceHelperField(
                        selectedPhases: $newResult.selectedPhases,
                        mohmsValue: $newResult.insulationResistanceMohms,
                        legacyValue: $newResult.insulationResistance,
                        testVoltage: $newResult.irTestVoltage,
                        phaseErrorMessage: currentCircuitErrorMessage(for: "Phase"),
                        resultErrorMessage: currentCircuitErrorMessage(for: "IR Result (MΩ)")
                    )

                    PolarityHelperField(
                        value: $newResult.polarityTest,
                        errorMessage: currentCircuitErrorMessage(for: "Polarity Test")
                    )

                    FaultLoopImpedanceHelperField(
                        value: $newResult.faultLoopImpedance,
                        protectionValue: $newResult.protectionSizeType,
                        testMethodValue: $newResult.testMethod,
                        systemVoltageValue: $newResult.systemVoltage,
                        disconnectionTimeValue: $newResult.disconnectionTime,
                        activeConductorSizeValue: $newResult.cableSize,
                        earthConductorSizeValue: $newResult.earthConductorSize,
                        mainIsolatorSupplyTypeValue: $newResult.mainIsolatorSupplyType,
                        mainIsolatorActiveZsValue: $newResult.mainIsolatorActiveZs,
                        mainIsolatorPhaseAZsValue: $newResult.mainIsolatorPhaseAZs,
                        mainIsolatorPhaseBZsValue: $newResult.mainIsolatorPhaseBZs,
                        mainIsolatorPhaseCZsValue: $newResult.mainIsolatorPhaseCZs,
                        errorMessage: currentCircuitErrorMessage(for: "Fault Loop Impedance")
                    )

                    PassFailField(
                        title: "Operational Test",
                        selection: $newResult.operationalTest,
                        helperText: "Record whether the circuit or equipment operated correctly.",
                        errorMessage: currentCircuitErrorMessage(for: "Operational Test")
                    )

                    Button(action: attemptAddCircuit) {
                        Text("+ Add Circuit")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .padding(.vertical, 14)
                            .background(canAddCircuit ? brandYellow : Color(.systemGray5))
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button(action: resetCircuitEntry) {
                        Text("Clear Current Entry")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .padding(.vertical, 10)
                            .background(Color.black)
                            .foregroundColor(brandYellow)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Text("Saved circuits can be duplicated and reordered below.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            TestResultsSection(title: "Saved Circuits (\(testResults.count))", brandYellow: brandYellow) {
                if testResults.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No circuits added yet.")
                            .foregroundColor(.secondary)

                        if showValidationErrors {
                            InlineValidationText(message: "Add at least one complete circuit before previewing or generating the PDF.")
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(testResults.enumerated()), id: \.element.id) { index, result in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Circuit \(index + 1)")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(result.circuitOrEquipment.isEmpty ? "Not provided" : result.circuitOrEquipment)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text(displayValue(result.testDate))
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }

                                if !result.isComplete {
                                    ValidationNotice(
                                        title: "Circuit \(index + 1) Is Incomplete",
                                        messages: result.missingRequiredFields.map { "\($0) is required." }
                                    )
                                }

                                savedCircuitRow("Visual Inspection", value: result.visualInspection)
                                savedCircuitRow("Circuit No.", value: result.circuitNo)
                                savedCircuitRow("Cable Size", value: result.cableSize)
                                savedCircuitRow("Protection", value: result.protectionSizeType)
                                savedCircuitRow("Neutral No.", value: result.neutralNo)
                                savedCircuitRow("Earth Continuity", value: result.earthContinuity)
                                savedCircuitRow("RCD", value: result.displayRCDValue)
                                savedCircuitRow("Phase", value: result.formattedSelectedPhases)
                                savedCircuitRow("IR Result (MΩ)", value: result.irResultValue)
                                savedCircuitRow("Polarity Test", value: result.polarityTest)
                                savedCircuitRow("Fault Loop Impedance", value: result.isMainIsolator ? result.mainIsolatorFaultLoopSummary : result.faultLoopImpedance)
                                savedCircuitRow("Operational Test", value: result.operationalTest)

                                HStack(spacing: 12) {
                                    Button(action: {
                                        duplicateCircuit(result)
                                    }) {
                                        Text("Duplicate")
                                            .font(.subheadline.bold())
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color.black)
                                            .foregroundColor(brandYellow)
                                            .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)

                                    Button(action: {
                                        editingResult = result
                                        showEditModal = true
                                    }) {
                                        Text("Edit")
                                            .font(.subheadline.bold())
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(brandYellow)
                                            .foregroundColor(.black)
                                            .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)

                                    Button(role: .destructive, action: {
                                        removeCircuit(result)
                                    }) {
                                        Text("Delete")
                                            .font(.subheadline.bold())
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color.red)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)
                                }

                                HStack(spacing: 12) {
                                    Button(action: {
                                        moveCircuit(result, direction: -1)
                                    }) {
                                        Label("Move Up", systemImage: "arrow.up")
                                            .font(.subheadline.bold())
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color(.systemGray5))
                                            .foregroundColor(.black)
                                            .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isFirst(result))

                                    Button(action: {
                                        moveCircuit(result, direction: 1)
                                    }) {
                                        Label("Move Down", systemImage: "arrow.down")
                                            .font(.subheadline.bold())
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color(.systemGray5))
                                            .foregroundColor(.black)
                                            .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isLast(result))
                                }
                            }
                            .padding(16)
                            .background(Color.npSecondarySurface)
                            .cornerRadius(14)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showEditModal) {
            if let editingResult,
               let idx = testResults.firstIndex(where: { $0.id == editingResult.id }) {
                TestResultEditView(result: $testResults[idx], isPresented: $showEditModal)
            }
        }
    }

    private func savedCircuitRow(_ title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            Spacer(minLength: 12)
            Text(displayValue(value))
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func displayValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Not provided" : value
    }

    private func currentCircuitErrorMessage(for field: String) -> String? {
        guard showEntryValidationErrors else { return nil }
        return currentCircuitValidationIssues.contains(field) ? "\(field) is required." : nil
    }

    private func attemptAddCircuit() {
        showEntryValidationErrors = true
        guard canAddCircuit else { return }

        var result = newResult
        result.testDate = Self.testDateFormatter.string(from: newTestDate)
        testResults.append(result)
        resetCircuitEntry()
    }

    private func removeCircuit(_ result: TestResult) {
        guard let index = testResults.firstIndex(where: { $0.id == result.id }) else { return }
        testResults.remove(at: index)
    }

    private func duplicateCircuit(_ result: TestResult) {
        guard let index = testResults.firstIndex(where: { $0.id == result.id }) else { return }
        testResults.insert(result.duplicated(), at: index + 1)
    }

    private func moveCircuit(_ result: TestResult, direction: Int) {
        guard let currentIndex = testResults.firstIndex(where: { $0.id == result.id }) else { return }

        let targetIndex = currentIndex + direction
        guard testResults.indices.contains(targetIndex) else { return }

        let movedItem = testResults.remove(at: currentIndex)
        testResults.insert(movedItem, at: targetIndex)
    }

    private func isFirst(_ result: TestResult) -> Bool {
        testResults.first?.id == result.id
    }

    private func isLast(_ result: TestResult) -> Bool {
        testResults.last?.id == result.id
    }

    private func resetCircuitEntry() {
        newResult = .blank()
        newTestDate = Date()
        showEntryValidationErrors = false
    }

    fileprivate static let testDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

private struct TestResultsSection<Content: View>: View {
    let title: String
    let brandYellow: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(brandYellow)
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(16)
            .background(Color.npSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(brandYellow, lineWidth: 1.5)
            )
            .cornerRadius(14)
        }
    }
}

private struct ValidationNotice: View {
    let title: String
    let messages: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.red)

            ForEach(messages, id: \.self) { message in
                InlineValidationText(message: message)
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.35), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

private struct InlineValidationText: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundColor(.red)
    }
}

private struct EntryTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textInputAutocapitalization: TextInputAutocapitalization = .sentences
    var helperText: String? = nil
    var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(textInputAutocapitalization)
                .autocorrectionDisabled()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(errorMessage == nil ? Color.clear : Color.red, lineWidth: 1)
                )

            if let helperText {
                Text(helperText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                InlineValidationText(message: errorMessage)
            }
        }
    }
}

private struct IdentifierField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var helperText: String? = nil
    var errorMessage: String? = nil

    var body: some View {
        EntryTextField(
            title: title,
            placeholder: placeholder,
            text: $text,
            textInputAutocapitalization: .characters,
            helperText: helperText,
            errorMessage: errorMessage
        )
        .onChange(of: text) { _, newValue in
            let sanitized = newValue.sanitizedIdentifier
            if sanitized != newValue {
                text = sanitized
            }
        }
    }
}

private struct MeasurementField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let unit: String
    var helperText: String? = nil
    var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            HStack(spacing: 10) {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .autocorrectionDisabled()
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(errorMessage == nil ? Color.clear : Color.red, lineWidth: 1)
                    )

                Text(unit)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.npFieldSurface)
                    .cornerRadius(8)
            }

            if let helperText {
                Text(helperText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                InlineValidationText(message: errorMessage)
            }
        }
    }
}

private struct StructuredCableSizeField: View {
    @Binding var value: String
    var errorMessage: String? = nil
    @State private var state = CableSizeInputState()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cable Size")
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            Menu {
                ForEach(CableSizeInputState.commonOptions, id: \.self) { option in
                    Button(option.isEmpty ? "Not Set" : option) {
                        state.selection = option
                        if option != "Other" {
                            state.customValue = ""
                        }
                    }
                }
            } label: {
                HStack {
                    Text(state.selectionLabel)
                        .foregroundColor(state.selection.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.npFieldSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(errorMessage == nil ? Color(uiColor: .separator) : .red, lineWidth: 1)
                )
                .cornerRadius(10)
            }

            if state.selection == "Other" {
                EntryTextField(
                    title: "Custom Cable Size",
                    placeholder: "e.g. 2 x 2.5",
                    text: $state.customValue,
                    keyboardType: .decimalPad,
                    helperText: "Use this if the size is not in the common list."
                )
            }

            if !state.summary.isEmpty {
                Text("Saved as: \(state.summary)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Choose a common cable size or enter a custom one. The PDF adds mm² automatically.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                InlineValidationText(message: errorMessage)
            }
        }
        .onAppear {
            state = CableSizeInputState.parse(value)
        }
        .onChange(of: state) { _, newState in
            let newValue = newState.summary
            if value != newValue {
                value = newValue
            }
        }
        .onChange(of: value) { _, newValue in
            let parsedState = CableSizeInputState.parse(newValue)
            if parsedState != state {
                state = parsedState
            }
        }
    }
}

private struct CableSizeInputState: Equatable {
    static let commonOptions = ["", "1.0", "1.5", "2.5", "4", "6", "10", "16", "25", "35", "50", "70", "95", "120", "Other"]

    var selection = ""
    var customValue = ""

    var selectionLabel: String {
        selection.isEmpty ? "Select Cable Size" : selection
    }

    var summary: String {
        selection == "Other" ? customValue.normalizedFieldValue : selection
    }

    static func parse(_ rawValue: String) -> CableSizeInputState {
        let trimmedValue = rawValue.normalizedFieldValue

        guard !trimmedValue.isEmpty else {
            return CableSizeInputState()
        }

        if let match = commonOptions.first(where: { option in
            !option.isEmpty && option != "Other" && option == trimmedValue
        }) {
            return CableSizeInputState(selection: match, customValue: "")
        }

        return CableSizeInputState(selection: "Other", customValue: trimmedValue)
    }
}

private struct PassFailField: View {
    let title: String
    @Binding var selection: String
    var helperText: String? = nil
    var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            Picker(title, selection: $selection) {
                Text("Not Set").tag("")
                Text("Pass").tag("Pass")
                Text("Fail").tag("Fail")
            }
            .pickerStyle(.segmented)

            if let helperText {
                Text(helperText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                InlineValidationText(message: errorMessage)
            }
        }
    }
}

private enum SuggestedAssessment {
    case pass
    case fail
    case needsReference
    case notApplicable

    var title: String {
        switch self {
        case .pass:
            return "Pass"
        case .fail:
            return "Fail"
        case .needsReference:
            return "Needs Reference"
        case .notApplicable:
            return "N/A"
        }
    }

    var tint: Color {
        switch self {
        case .pass:
            return .green
        case .fail:
            return .red
        case .needsReference:
            return .orange
        case .notApplicable:
            return .secondary
        }
    }

    var icon: String {
        switch self {
        case .pass:
            return "checkmark.circle.fill"
        case .fail:
            return "xmark.octagon.fill"
        case .needsReference:
            return "book.closed.fill"
        case .notApplicable:
            return "minus.circle.fill"
        }
    }
}

private struct AssessmentHelperCard: View {
    let outcome: SuggestedAssessment
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: outcome.icon)
                    .foregroundColor(outcome.tint)
                Text("Suggested assessment: \(outcome.title)")
                    .font(.caption.bold())
                    .foregroundColor(outcome.tint)
            }

            Text(message)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(12)
        .background(outcome.tint.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(outcome.tint.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

private struct EarthContinuityHelperField: View {
    @Binding var value: String
    var errorMessage: String? = nil

    private var trimmedValue: String {
        value.normalizedFieldValue
    }

    private var shouldShowSummary: Bool {
        !trimmedValue.isEmpty
    }

    private var continuityResult: EarthContinuityResult {
        EarthContinuityEvaluator.evaluate(trimmedValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MeasurementField(
                title: "Earth Continuity",
                placeholder: "0.24",
                text: $value,
                unit: "Ω",
                helperText: "Enter the measured value exactly as taken. PDF exports the exact value entered.",
                errorMessage: errorMessage
            )

            if shouldShowSummary {
                EarthContinuitySummaryCard(result: continuityResult)
            }
        }
    }
}

private enum EarthContinuityAssessment {
    case excellent
    case acceptable
    case high
    case invalid

    var title: String {
        switch self {
        case .excellent:
            return "Excellent"
        case .acceptable:
            return "Acceptable"
        case .high:
            return "High - Check"
        case .invalid:
            return "Invalid"
        }
    }

    var tint: Color {
        switch self {
        case .excellent:
            return .green
        case .acceptable:
            return .blue
        case .high:
            return .orange
        case .invalid:
            return .secondary
        }
    }

    var icon: String {
        switch self {
        case .excellent:
            return "checkmark.circle.fill"
        case .acceptable:
            return "equal.circle.fill"
        case .high:
            return "exclamationmark.circle.fill"
        case .invalid:
            return "number.circle.fill"
        }
    }

    var expectedRangeText: String {
        switch self {
        case .excellent:
            return "Typical guidance range 0.0 - 0.5 Ω"
        case .acceptable:
            return "Typical guidance range 0.5 - 1.5 Ω"
        case .high:
            return "Typical guidance range above 1.5 Ω may need context"
        case .invalid:
            return "Enter a numeric resistance value in ohms"
        }
    }

    var confidenceLabel: String {
        switch self {
        case .excellent, .acceptable:
            return "Within Typical Range"
        case .high, .invalid:
            return "Requires Context"
        }
    }

    var note: String {
        switch self {
        case .excellent:
            return "Low resistance indicates good continuity."
        case .acceptable:
            return "Value is within a typical range for many installations."
        case .high:
            return "Higher resistance may indicate loose connections, poor joints, or long cable runs."
        case .invalid:
            return "Enter a numeric earth continuity value to see guidance."
        }
    }
}

private struct EarthContinuityResult {
    let measured: Double?
    let assessment: EarthContinuityAssessment
    let positionLabel: String
    let disclaimer: String

    var confidenceLabel: String {
        assessment.confidenceLabel
    }

    var expectedRangeText: String {
        assessment.expectedRangeText
    }

    var note: String {
        assessment.note
    }
}

private enum EarthContinuityEvaluator {
    static func evaluate(_ rawValue: String) -> EarthContinuityResult {
        guard let measured = rawValue.numericDoubleValue, measured >= 0 else {
            return EarthContinuityResult(
                measured: nil,
                assessment: .invalid,
                positionLabel: "--",
                disclaimer: "Actual expected values depend on cable length and size."
            )
        }

        if measured <= 0.5 {
            return EarthContinuityResult(
                measured: measured,
                assessment: .excellent,
                positionLabel: "Lower range",
                disclaimer: "Actual expected values depend on cable length and size."
            )
        }

        if measured <= 1.5 {
            return EarthContinuityResult(
                measured: measured,
                assessment: .acceptable,
                positionLabel: "Mid range",
                disclaimer: "Actual expected values depend on cable length and size."
            )
        }

        return EarthContinuityResult(
            measured: measured,
            assessment: .high,
            positionLabel: "Upper range",
            disclaimer: "Actual expected values depend on cable length and size."
        )
    }
}

private struct EarthContinuitySummaryCard: View {
    let result: EarthContinuityResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: result.assessment.icon)
                    .foregroundColor(result.assessment.tint)
                Text("Earth Continuity Guidance")
                    .font(.caption.bold())
                    .foregroundColor(result.assessment.tint)
            }

            ZsSummaryRow(title: "Measured", value: displayValue(for: result.measured))
            ZsSummaryRow(title: "Assessment", value: result.assessment.title, valueColor: result.assessment.tint)
            ZsSummaryRow(title: "Expected", value: result.expectedRangeText)
            ZsSummaryRow(title: "Confidence", value: result.confidenceLabel, valueColor: result.assessment.tint)
            ZsSummaryRow(title: "Position", value: result.positionLabel)

            VStack(alignment: .leading, spacing: 4) {
                Text("Note")
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                Text(result.note)
                    .font(.caption)
                    .foregroundColor(.primary)
            }

            Text(result.disclaimer)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(result.assessment.tint.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(result.assessment.tint.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func displayValue(for value: Double?) -> String {
        guard let value else { return "--" }

        if value >= 1 {
            return String(format: "%.2f Ω", value)
        }

        return String(format: "%.3f Ω", value)
    }
}

private struct InsulationResistanceHelperField: View {
    @Binding var selectedPhases: [String]
    @Binding var mohmsValue: String
    @Binding var legacyValue: String
    @Binding var testVoltage: String
    var phaseErrorMessage: String? = nil
    var resultErrorMessage: String? = nil

    private let phaseOptions = ["A", "B", "C"]
    private let voltageOptions = ["250V", "500V", "1000V"]

    private var trimmedValue: String {
        mohmsValue.normalizedFieldValue
    }

    private var shouldShowSummary: Bool {
        !trimmedValue.isEmpty
    }

    private var insulationResult: InsulationResistanceResult {
        InsulationResistanceEvaluator.evaluate(trimmedValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Insulation Resistance")
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Phase")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    ForEach(phaseOptions, id: \.self) { phase in
                        Button(action: {
                            togglePhase(phase)
                        }) {
                            Text(phase)
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(selectedPhases.contains(phase) ? Color.npBrandYellow : Color.npFieldSurface)
                                .foregroundColor(.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedPhases.contains(phase) ? Color.npBrandYellow : Color(uiColor: .separator), lineWidth: 1)
                                )
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(selectedPhasesDisplayText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let phaseErrorMessage {
                    InlineValidationText(message: phaseErrorMessage)
                }
            }

            MeasurementField(
                title: "IR Result",
                placeholder: "200",
                text: $mohmsValue,
                unit: "MΩ",
                helperText: "Enter the measured value exactly as taken. PDF exports the exact value entered.",
                errorMessage: resultErrorMessage
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("IR Test Voltage")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Picker("IR Test Voltage", selection: $testVoltage) {
                    ForEach(voltageOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }

            if shouldShowSummary {
                InsulationResistanceSummaryCard(result: insulationResult)
            }
        }
        .onAppear {
            if mohmsValue.normalizedFieldValue.isEmpty, !legacyValue.normalizedFieldValue.isEmpty {
                mohmsValue = legacyValue.normalizedFieldValue
            }
            if testVoltage.normalizedFieldValue.isEmpty {
                testVoltage = TestResult.defaultIRTestVoltage
            }
            selectedPhases = normalizedPhases(selectedPhases)
        }
        .onChange(of: mohmsValue) { _, newValue in
            let normalizedValue = newValue.normalizedFieldValue
            if legacyValue != normalizedValue {
                legacyValue = normalizedValue
            }
        }
        .onChange(of: legacyValue) { _, newValue in
            if mohmsValue.normalizedFieldValue.isEmpty, !newValue.normalizedFieldValue.isEmpty {
                mohmsValue = newValue.normalizedFieldValue
            }
        }
        .onChange(of: selectedPhases) { _, newValue in
            let normalizedValue = normalizedPhases(newValue)
            if normalizedValue != newValue {
                selectedPhases = normalizedValue
            }
        }
    }

    private var selectedPhasesDisplayText: String {
        let displayValue = normalizedPhases(selectedPhases).joined(separator: "+")
        return displayValue.isEmpty ? "Select one or more phases." : "Saved as: \(displayValue)"
    }

    private func togglePhase(_ phase: String) {
        var updatedPhases = selectedPhases
        if let index = updatedPhases.firstIndex(of: phase) {
            updatedPhases.remove(at: index)
        } else {
            updatedPhases.append(phase)
        }
        selectedPhases = normalizedPhases(updatedPhases)
    }

    private func normalizedPhases(_ phases: [String]) -> [String] {
        phaseOptions.filter { phases.contains($0) }
    }
}

private enum InsulationResistanceAssessment {
    case strong
    case typical
    case low
    case invalid

    var title: String {
        switch self {
        case .strong:
            return "Strong Reading"
        case .typical:
            return "Typical Reading"
        case .low:
            return "Low - Check"
        case .invalid:
            return "Invalid"
        }
    }

    var tint: Color {
        switch self {
        case .strong:
            return .green
        case .typical:
            return .blue
        case .low:
            return .orange
        case .invalid:
            return .secondary
        }
    }

    var icon: String {
        switch self {
        case .strong:
            return "checkmark.circle.fill"
        case .typical:
            return "equal.circle.fill"
        case .low:
            return "exclamationmark.circle.fill"
        case .invalid:
            return "number.circle.fill"
        }
    }

    var confidence: String {
        switch self {
        case .strong, .typical:
            return "Guidance Only"
        case .low, .invalid:
            return "Requires Test Context"
        }
    }

    var note: String {
        switch self {
        case .strong:
            return "Higher insulation resistance generally indicates a stronger result."
        case .typical:
            return "This reading may be typical, but interpretation depends on test conditions."
        case .low:
            return "Lower insulation resistance may need closer review before relying on the result."
        case .invalid:
            return "Enter a numeric insulation resistance value to see guidance."
        }
    }
}

private struct InsulationResistanceResult {
    let measured: Double?
    let assessment: InsulationResistanceAssessment
    let disclaimer: String
}

private enum InsulationResistanceEvaluator {
    static func evaluate(_ rawValue: String) -> InsulationResistanceResult {
        guard let measured = rawValue.numericDoubleValue, measured >= 0 else {
            return InsulationResistanceResult(
                measured: nil,
                assessment: .invalid,
                disclaimer: "Interpretation depends on test voltage and circuit conditions."
            )
        }

        if measured >= 10 {
            return InsulationResistanceResult(
                measured: measured,
                assessment: .strong,
                disclaimer: "Interpretation depends on test voltage and circuit conditions."
            )
        }

        if measured >= 1 {
            return InsulationResistanceResult(
                measured: measured,
                assessment: .typical,
                disclaimer: "Interpretation depends on test voltage and circuit conditions."
            )
        }

        return InsulationResistanceResult(
            measured: measured,
            assessment: .low,
            disclaimer: "Interpretation depends on test voltage and circuit conditions."
        )
    }
}

private struct InsulationResistanceSummaryCard: View {
    let result: InsulationResistanceResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: result.assessment.icon)
                    .foregroundColor(result.assessment.tint)
                Text("Insulation Resistance Guidance")
                    .font(.caption.bold())
                    .foregroundColor(result.assessment.tint)
            }

            ZsSummaryRow(title: "Measured", value: displayValue(for: result.measured))
            ZsSummaryRow(title: "Assessment", value: result.assessment.title, valueColor: result.assessment.tint)
            ZsSummaryRow(title: "Confidence", value: result.assessment.confidence, valueColor: result.assessment.tint)

            VStack(alignment: .leading, spacing: 4) {
                Text("Note")
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                Text(result.assessment.note)
                    .font(.caption)
                    .foregroundColor(.primary)
            }

            Text(result.disclaimer)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(result.assessment.tint.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(result.assessment.tint.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func displayValue(for value: Double?) -> String {
        guard let value else { return "--" }

        if value >= 10 {
            return String(format: "%.0f MΩ", value)
        }

        if value >= 1 {
            return String(format: "%.2f MΩ", value)
        }

        return String(format: "%.3f MΩ", value)
    }
}

private struct FaultLoopImpedanceHelperField: View {
    @Binding var value: String
    @Binding var protectionValue: String
    @Binding var testMethodValue: String
    @Binding var systemVoltageValue: String
    @Binding var disconnectionTimeValue: String
    @Binding var activeConductorSizeValue: String
    @Binding var earthConductorSizeValue: String
    @Binding var mainIsolatorSupplyTypeValue: String
    @Binding var mainIsolatorActiveZsValue: String
    @Binding var mainIsolatorPhaseAZsValue: String
    @Binding var mainIsolatorPhaseBZsValue: String
    @Binding var mainIsolatorPhaseCZsValue: String
    var errorMessage: String? = nil

    private var protectionState: ProtectionInputState {
        ProtectionInputState.parse(protectionValue)
    }

    private var selectedTestMethod: ZsTestMethod {
        ZsTestMethod(rawValue: testMethodValue.normalizedFieldValue) ?? .zs
    }

    private var selectedSystemVoltage: ZsSystemVoltage {
        ZsSystemVoltage(rawValue: systemVoltageValue.normalizedFieldValue) ?? .v230
    }

    private var selectedDisconnectionTime: ZsDisconnectionTime {
        ZsDisconnectionTime(rawValue: disconnectionTimeValue.normalizedFieldValue) ?? .s0_4
    }

    private var selectedActiveConductorSize: String {
        activeConductorSizeValue.normalizedFieldValue
    }

    private var selectedEarthConductorSize: String {
        earthConductorSizeValue.normalizedFieldValue
    }

    private var selectedMainIsolatorSupplyType: MainIsolatorSupplyType {
        MainIsolatorSupplyType(rawValue: mainIsolatorSupplyTypeValue.normalizedFieldValue) ?? .singlePhase
    }

    private var shouldShowSummary: Bool {
        if protectionState.isMainIsolator {
            return !mainIsolatorActiveZsValue.normalizedFieldValue.isEmpty ||
                !mainIsolatorPhaseAZsValue.normalizedFieldValue.isEmpty ||
                !mainIsolatorPhaseBZsValue.normalizedFieldValue.isEmpty ||
                !mainIsolatorPhaseCZsValue.normalizedFieldValue.isEmpty
        }

        return !value.normalizedFieldValue.isEmpty ||
            !protectionState.summary.isEmpty ||
            selectedTestMethod != .zs ||
            selectedSystemVoltage != .v230 ||
            selectedDisconnectionTime != .s0_4 ||
            !selectedActiveConductorSize.isEmpty ||
            !selectedEarthConductorSize.isEmpty
    }

    private var checkResult: ZsCheckResult {
        ZsChecker.evaluate(
            measuredText: value,
            protectionState: protectionState,
            testMethod: selectedTestMethod,
            systemVoltage: selectedSystemVoltage,
            disconnectionTime: selectedDisconnectionTime,
            activeConductorSizeText: selectedActiveConductorSize,
            earthConductorSizeText: selectedEarthConductorSize
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if protectionState.isMainIsolator {
                mainIsolatorRecordOnlySection
            } else {
            MeasurementField(
                title: selectedTestMethod == .r1PlusR2 ? "Measured R1+R2" : "Fault Loop Impedance (Zs)",
                placeholder: "0.44",
                text: $value,
                unit: "Ω",
                helperText: "Enter the measured value exactly as taken. PDF exports the exact value entered.",
                errorMessage: errorMessage
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("Test Method")
                    .font(.caption.bold())
                    .foregroundColor(.primary)

                Menu {
                    ForEach(ZsTestMethod.allCases) { option in
                        Button(option.label) {
                            testMethodValue = option.rawValue
                        }
                    }
                } label: {
                    selectionMenuLabel(
                        title: selectedTestMethod.label,
                        isPlaceholder: false
                    )
                }
            }

            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("System Voltage")
                        .font(.caption.bold())
                        .foregroundColor(.primary)

                    Menu {
                        ForEach(ZsSystemVoltage.allCases) { option in
                            Button(option.label) {
                                systemVoltageValue = option.rawValue
                            }
                        }
                    } label: {
                        selectionMenuLabel(
                            title: selectedSystemVoltage.label,
                            isPlaceholder: selectedSystemVoltage == .notSet
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Disconnection Time")
                        .font(.caption.bold())
                        .foregroundColor(.primary)

                    Menu {
                        ForEach(ZsDisconnectionTime.displayOptions) { option in
                            Button(option.pickerLabel) {
                                disconnectionTimeValue = option.rawValue
                            }
                        }
                    } label: {
                        selectionMenuLabel(
                            title: selectedDisconnectionTime.pickerLabel,
                            isPlaceholder: selectedDisconnectionTime == .notSet
                        )
                    }
                }
            }

            Text("AS/NZS 3000 guidance:\nUse 0.4s for most 230V final subcircuits.\nUse 5.0s for submains/distribution circuits where permitted.")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if selectedTestMethod == .r1PlusR2 {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Active Conductor Size")
                            .font(.caption.bold())
                            .foregroundColor(.primary)

                        Menu {
                            ForEach(R1R2ConductorSizeSelection.options, id: \.self) { option in
                                Button(R1R2ConductorSizeSelection.label(for: option)) {
                                    activeConductorSizeValue = option
                                }
                            }
                        } label: {
                            selectionMenuLabel(
                                title: R1R2ConductorSizeSelection.label(for: selectedActiveConductorSize),
                                isPlaceholder: selectedActiveConductorSize.isEmpty
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Earth Conductor Size")
                            .font(.caption.bold())
                            .foregroundColor(.primary)

                        Menu {
                            ForEach(R1R2ConductorSizeSelection.options, id: \.self) { option in
                                Button(R1R2ConductorSizeSelection.label(for: option)) {
                                    earthConductorSizeValue = option
                                }
                            }
                        } label: {
                            selectionMenuLabel(
                                title: R1R2ConductorSizeSelection.label(for: selectedEarthConductorSize),
                                isPlaceholder: selectedEarthConductorSize.isEmpty
                            )
                        }
                    }
                }
            }

            Text("Result based on AS/NZS 3000 Table 8.1 or Table 8.2 where available.")
                .font(.caption)
                .foregroundColor(.secondary)

            if shouldShowSummary {
                ZsCheckSummaryCard(result: checkResult)
            }
            }
        }
        .onAppear {
            if protectionState.isMainIsolator {
                applyMainIsolatorDefaults()
            } else {
                applyDefaultDisconnectionTimeIfNeeded()
            }
        }
        .onChange(of: testMethodValue) { _, _ in
            applyDefaultDisconnectionTimeIfNeeded()
        }
        .onChange(of: protectionValue) { _, _ in
            if protectionState.isMainIsolator {
                applyMainIsolatorDefaults()
            }
        }
    }

    private func selectionMenuLabel(title: String, isPlaceholder: Bool) -> some View {
        HStack {
            Text(title)
                .foregroundColor(isPlaceholder ? .secondary : .primary)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.npFieldSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(uiColor: .separator), lineWidth: 1)
        )
        .cornerRadius(10)
    }

    private func applyDefaultDisconnectionTimeIfNeeded() {
        if selectedTestMethod == .zs && disconnectionTimeValue.normalizedFieldValue.isEmpty {
            disconnectionTimeValue = ZsDisconnectionTime.s0_4.rawValue
        }
    }

    @ViewBuilder
    private var mainIsolatorRecordOnlySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fault Loop Impedance - Record Only")
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Supply Type")
                    .font(.caption.bold())
                    .foregroundColor(.primary)

                Menu {
                    ForEach(MainIsolatorSupplyType.allCases) { option in
                        Button(option.label) {
                            mainIsolatorSupplyTypeValue = option.rawValue
                        }
                    }
                } label: {
                    selectionMenuLabel(
                        title: selectedMainIsolatorSupplyType.label,
                        isPlaceholder: false
                    )
                }
            }

            if selectedMainIsolatorSupplyType == .threePhase {
                MeasurementField(title: "A Phase Zs", placeholder: "0.100", text: $mainIsolatorPhaseAZsValue, unit: "Ω")
                MeasurementField(title: "B Phase Zs", placeholder: "0.120", text: $mainIsolatorPhaseBZsValue, unit: "Ω")
                MeasurementField(title: "C Phase Zs", placeholder: "0.200", text: $mainIsolatorPhaseCZsValue, unit: "Ω")
            } else {
                MeasurementField(title: "Active Zs", placeholder: "0.100", text: $mainIsolatorActiveZsValue, unit: "Ω")
            }

            Text("Main isolator does not provide automatic fault disconnection.\nVerify upstream protective device.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if shouldShowSummary {
                MainIsolatorZsSummaryCard(
                    supplyType: selectedMainIsolatorSupplyType,
                    activeZs: mainIsolatorActiveZsValue,
                    phaseAZs: mainIsolatorPhaseAZsValue,
                    phaseBZs: mainIsolatorPhaseBZsValue,
                    phaseCZs: mainIsolatorPhaseCZsValue
                )
            }
        }
    }

    private func applyMainIsolatorDefaults() {
        if mainIsolatorSupplyTypeValue.normalizedFieldValue.isEmpty {
            mainIsolatorSupplyTypeValue = MainIsolatorSupplyType.singlePhase.rawValue
        }
    }
}

private enum ZsCheckOutcome {
    case pass
    case fail
    case incomplete
    case reviewRequired

    var title: String {
        switch self {
        case .pass:
            return "PASS"
        case .fail:
            return "FAIL"
        case .incomplete:
            return "Incomplete"
        case .reviewRequired:
            return "Review Required"
        }
    }

    var tint: Color {
        switch self {
        case .pass:
            return .green
        case .fail:
            return .red
        case .incomplete:
            return .orange
        case .reviewRequired:
            return .orange
        }
    }

    var icon: String {
        switch self {
        case .pass:
            return "checkmark.circle.fill"
        case .fail:
            return "xmark.octagon.fill"
        case .incomplete:
            return "exclamationmark.circle.fill"
        case .reviewRequired:
            return "exclamationmark.triangle.fill"
        }
    }
}

private enum ZsConfidenceLevel {
    case high
    case medium
    case reviewRequired

    var title: String {
        switch self {
        case .high:
            return "High"
        case .medium:
            return "Medium"
        case .reviewRequired:
            return "Review Required"
        }
    }

    var tint: Color {
        switch self {
        case .high:
            return .green
        case .medium:
            return .orange
        case .reviewRequired:
            return .orange
        }
    }
}

private enum ZsTestMethod: String, CaseIterable, Identifiable {
    case zs = "Zs"
    case r1PlusR2 = "R1+R2"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .zs:
            return "Zs (Loop Impedance)"
        case .r1PlusR2:
            return "R1+R2 (Resistance Method)"
        }
    }

    var assumptionsLabel: String {
        switch self {
        case .zs:
            return "Zs (Table 8.1)"
        case .r1PlusR2:
            return "R1+R2 (Table 8.2)"
        }
    }

    var referenceTable: ZsReferenceSourceTable {
        switch self {
        case .zs:
            return .table8_1
        case .r1PlusR2:
            return .table8_2
        }
    }
}

private enum ZsReferenceSourceTable: String {
    case table8_1 = "Table 8.1"
    case table8_2 = "Table 8.2"

    var verifiedLabel: String {
        "AS/NZS 3000:2018 \(rawValue) (verified)"
    }

    var standardLabel: String {
        "AS/NZS 3000:2018 \(rawValue)"
    }
}

private enum ZsSystemVoltage: String, CaseIterable, Identifiable {
    case notSet = ""
    case v230 = "230V"
    case v240 = "240V"
    case v400 = "400V"
    case v415 = "415V"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .notSet:
            return "Not Set"
        case .v230:
            return rawValue
        case .v240:
            return rawValue
        case .v400:
            return rawValue
        case .v415:
            return rawValue
        }
    }
}

private enum ZsDisconnectionTime: String, CaseIterable, Identifiable {
    case notSet = ""
    case s0_4 = "0.4s"
    case s5_0 = "5.0s"
    case s0_1 = "0.1s"
    case s0_2 = "0.2s"
    case s2_0 = "2.0s"

    var id: String { rawValue }

    static let displayOptions: [ZsDisconnectionTime] = [
        .s0_4,
        .s5_0,
        .s0_1,
        .s0_2,
        .s2_0
    ]

    var label: String {
        switch self {
        case .notSet:
            return "Not Set"
        case .s0_1:
            return rawValue
        case .s0_2:
            return rawValue
        case .s0_4:
            return rawValue
        case .s2_0:
            return rawValue
        case .s5_0:
            return rawValue
        }
    }

    var pickerLabel: String {
        switch self {
        case .notSet:
            return "Not Set"
        case .s0_4:
            return "0.4s - Final circuit"
        case .s5_0:
            return "5.0s - Submain/fixed"
        case .s0_1:
            return "0.1s - Special"
        case .s0_2:
            return "0.2s - Special final"
        case .s2_0:
            return "2.0s - Distribution"
        }
    }
}

private enum ZsLookupDeviceType: String {
    case mcb = "MCB"
    case rcbo = "RCBO"
    case hrcFuse = "HRC Fuse"
}

private enum ZsTripCurve: String {
    case typeB = "Type B"
    case typeC = "Type C"
    case typeD = "Type D"
}

private enum MainIsolatorSupplyType: String, CaseIterable, Identifiable {
    case singlePhase = "Single Phase"
    case threePhase = "Three Phase"

    var id: String { rawValue }

    var label: String { rawValue }
}

private enum R1R2ConductorSizeSelection {
    static let options = CableSizeInputState.commonOptions.filter { !$0.isEmpty && $0 != "Other" }

    static func label(for value: String) -> String {
        let trimmedValue = value.normalizedFieldValue
        guard !trimmedValue.isEmpty else { return "Not Set" }
        return "\(formattedDisplaySize(for: trimmedValue)) mm²"
    }

    static func lookupKey(for value: String) -> String? {
        let trimmedValue = value.normalizedFieldValue
        guard !trimmedValue.isEmpty, let numericValue = Double(trimmedValue) else { return nil }
        return String(format: "%.1f", numericValue)
    }

    static func formattedDisplaySize(for value: String) -> String {
        guard let numericValue = Double(value.normalizedFieldValue) else { return value.normalizedFieldValue }
        return numericValue.rounded(.towardZero) == numericValue
            ? String(format: "%.1f", numericValue)
            : String(format: "%.1f", numericValue)
    }
}

private enum ZsMissingField {
    case measuredZs
    case protectiveDeviceType
    case protectiveDeviceRating
    case curve
    case voltage
    case disconnectionTime
    case activeConductorSize
    case earthConductorSize

    var label: String {
        switch self {
        case .measuredZs:
            return "measured Zs"
        case .protectiveDeviceType:
            return "protective device type"
        case .protectiveDeviceRating:
            return "protective device rating"
        case .curve:
            return "curve"
        case .voltage:
            return "voltage"
        case .disconnectionTime:
            return "disconnection time"
        case .activeConductorSize:
            return "active conductor size"
        case .earthConductorSize:
            return "earth conductor size"
        }
    }
}

private struct ZsLookupKey: Hashable {
    let method: ZsTestMethod
    let deviceType: ZsLookupDeviceType
    let rating: String
    let curve: ZsTripCurve
    let systemVoltage: ZsSystemVoltage
    let disconnectionTime: ZsDisconnectionTime
}

private struct ZsLookupRow {
    let table: ZsReferenceSourceTable
    let method: ZsTestMethod
    let deviceType: ZsLookupDeviceType
    let rating: String
    let curve: ZsTripCurve
    let voltage: ZsSystemVoltage
    let disconnectionTime: ZsDisconnectionTime
    let maxAllowedZs: Double
    let referenceLabel: String
    let isVerified: Bool

    var key: ZsLookupKey {
        ZsLookupKey(
            method: method,
            deviceType: deviceType,
            rating: rating,
            curve: curve,
            systemVoltage: voltage,
            disconnectionTime: disconnectionTime
        )
    }

}

private struct ZsCheckResult {
    let method: ZsTestMethod
    let measuredZs: Double?
    let maxAllowedZs: Double?
    let maxRphe: Double?
    let maxRe: Double?
    let margin: Double?
    let outcome: ZsCheckOutcome
    let confidence: ZsConfidenceLevel
    let assumptionsUsed: String
    let message: String
}

private struct R1R2LookupKey: Hashable {
    let deviceType: ZsLookupDeviceType
    let ratingAmps: String
    let activeSizeMM2: String
    let earthSizeMM2: String
    let breakerCurve: ZsTripCurve?
    let systemVoltage: ZsSystemVoltage
    let disconnectionTime: ZsDisconnectionTime
}

private struct R1R2LookupRow {
    let deviceType: ZsLookupDeviceType
    let ratingAmps: String
    let activeSizeMM2: String
    let earthSizeMM2: String
    let breakerCurve: ZsTripCurve?
    let systemVoltage: ZsSystemVoltage
    let disconnectionTime: ZsDisconnectionTime
    let maxRphe: Double
    let maxRe: Double
    let sourceLabel: String
    let isVerified: Bool

    var maxR1R2: Double {
        maxRphe + maxRe
    }

    var key: R1R2LookupKey {
        R1R2LookupKey(
            deviceType: deviceType,
            ratingAmps: ratingAmps,
            activeSizeMM2: activeSizeMM2,
            earthSizeMM2: earthSizeMM2,
            breakerCurve: breakerCurve,
            systemVoltage: systemVoltage,
            disconnectionTime: disconnectionTime
        )
    }
}

private enum ZsReferenceTable {
    static let table8_1Rows: [ZsLookupRow] =
        verifiedMCBRows(
            curve: .typeB,
            values: [
                ("6A", 9.6), ("10A", 5.8), ("16A", 3.6), ("20A", 2.9),
                ("25A", 2.3), ("32A", 1.8), ("40A", 1.4), ("50A", 1.2),
                ("63A", 0.9), ("80A", 0.7), ("100A", 0.6), ("125A", 0.5),
                ("160A", 0.4), ("200A", 0.3)
            ]
        ) +
        verifiedMCBRows(
            curve: .typeC,
            values: [
                ("6A", 5.1), ("10A", 3.1), ("16A", 1.9), ("20A", 1.5),
                ("25A", 1.2), ("32A", 1.0), ("40A", 0.8), ("50A", 0.6),
                ("63A", 0.5), ("80A", 0.4), ("100A", 0.3), ("125A", 0.2),
                ("160A", 0.2), ("200A", 0.2)
            ]
        ) +
        verifiedMCBRows(
            curve: .typeD,
            values: [
                ("6A", 3.1), ("10A", 1.8), ("16A", 1.2), ("20A", 0.9),
                ("25A", 0.7), ("32A", 0.6), ("40A", 0.5), ("50A", 0.4),
                ("63A", 0.3), ("80A", 0.2), ("100A", 0.2), ("125A", 0.1),
                ("160A", 0.1), ("200A", 0.1)
            ]
        )

    static let table8_2Rows: [R1R2LookupRow] = [
        verifiedR1R2Rows(rating: "6A", activeSize: "1.0", earthSize: "1.0", typeB: (6.1, 3.1), typeC: (3.3, 1.6), typeD: (2.0, 1.0)),
        verifiedR1R2Rows(rating: "10A", activeSize: "1.0", earthSize: "1.0", typeB: (3.7, 1.8), typeC: (2.0, 1.0), typeD: (1.2, 0.6)),
        verifiedR1R2Rows(rating: "10A", activeSize: "1.5", earthSize: "1.5", typeB: (3.7, 1.8), typeC: (2.0, 1.0), typeD: (1.2, 0.6)),
        verifiedR1R2Rows(rating: "16A", activeSize: "1.5", earthSize: "1.5", typeB: (2.3, 1.2), typeC: (1.2, 0.6), typeD: (0.7, 0.4)),
        verifiedR1R2Rows(rating: "16A", activeSize: "2.5", earthSize: "2.5", typeB: (2.3, 1.2), typeC: (1.2, 0.6), typeD: (0.7, 0.4)),
        verifiedR1R2Rows(rating: "20A", activeSize: "2.5", earthSize: "2.5", typeB: (1.8, 0.9), typeC: (1.0, 0.5), typeD: (0.6, 0.3)),
        verifiedR1R2Rows(rating: "25A", activeSize: "4.0", earthSize: "2.5", typeB: (1.5, 0.9), typeC: (0.8, 0.5), typeD: (0.5, 0.3)),
        verifiedR1R2Rows(rating: "32A", activeSize: "4.0", earthSize: "2.5", typeB: (1.2, 0.7), typeC: (0.6, 0.4), typeD: (0.4, 0.2)),
        verifiedR1R2Rows(rating: "40A", activeSize: "6.0", earthSize: "2.5", typeB: (0.9, 0.6), typeC: (0.5, 0.3), typeD: (0.3, 0.2)),
        verifiedR1R2Rows(rating: "50A", activeSize: "10.0", earthSize: "4.0", typeB: (0.7, 0.5), typeC: (0.4, 0.3), typeD: (0.2, 0.2)),
        verifiedR1R2Rows(rating: "63A", activeSize: "16.0", earthSize: "6.0", typeB: (0.6, 0.4), typeC: (0.3, 0.2), typeD: (0.2, 0.1))
    ].flatMap { $0 } + [
        verifiedHRCFuseR1R2Row(rating: "6A", activeSize: "1.0", earthSize: "1.0", disconnectionTime: .s0_4, maxRphe: 7.4, maxRe: 3.7),
        verifiedHRCFuseR1R2Row(rating: "6A", activeSize: "1.0", earthSize: "1.0", disconnectionTime: .s5_0, maxRphe: 9.8, maxRe: 4.9),
        verifiedHRCFuseR1R2Row(rating: "10A", activeSize: "1.0", earthSize: "1.0", disconnectionTime: .s0_4, maxRphe: 4.1, maxRe: 2.0),
        verifiedHRCFuseR1R2Row(rating: "10A", activeSize: "1.0", earthSize: "1.0", disconnectionTime: .s5_0, maxRphe: 5.9, maxRe: 2.9),
        verifiedHRCFuseR1R2Row(rating: "10A", activeSize: "1.5", earthSize: "1.5", disconnectionTime: .s0_4, maxRphe: 4.1, maxRe: 2.0),
        verifiedHRCFuseR1R2Row(rating: "10A", activeSize: "1.5", earthSize: "1.5", disconnectionTime: .s5_0, maxRphe: 5.9, maxRe: 2.9),
        verifiedHRCFuseR1R2Row(rating: "16A", activeSize: "1.5", earthSize: "1.5", disconnectionTime: .s0_4, maxRphe: 2.0, maxRe: 1.0),
        verifiedHRCFuseR1R2Row(rating: "16A", activeSize: "1.5", earthSize: "1.5", disconnectionTime: .s5_0, maxRphe: 3.2, maxRe: 1.6),
        verifiedHRCFuseR1R2Row(rating: "16A", activeSize: "2.5", earthSize: "2.5", disconnectionTime: .s0_4, maxRphe: 2.0, maxRe: 1.0),
        verifiedHRCFuseR1R2Row(rating: "16A", activeSize: "2.5", earthSize: "2.5", disconnectionTime: .s5_0, maxRphe: 3.2, maxRe: 1.6),
        verifiedHRCFuseR1R2Row(rating: "20A", activeSize: "2.5", earthSize: "2.5", disconnectionTime: .s0_4, maxRphe: 1.3, maxRe: 0.7),
        verifiedHRCFuseR1R2Row(rating: "20A", activeSize: "2.5", earthSize: "2.5", disconnectionTime: .s5_0, maxRphe: 2.3, maxRe: 1.1),
        verifiedHRCFuseR1R2Row(rating: "25A", activeSize: "4.0", earthSize: "2.5", disconnectionTime: .s0_4, maxRphe: 1.0, maxRe: 0.6),
        verifiedHRCFuseR1R2Row(rating: "25A", activeSize: "4.0", earthSize: "2.5", disconnectionTime: .s5_0, maxRphe: 1.7, maxRe: 1.1),
        verifiedHRCFuseR1R2Row(rating: "32A", activeSize: "4.0", earthSize: "2.5", disconnectionTime: .s0_4, maxRphe: 0.8, maxRe: 0.5),
        verifiedHRCFuseR1R2Row(rating: "32A", activeSize: "4.0", earthSize: "2.5", disconnectionTime: .s5_0, maxRphe: 1.4, maxRe: 0.9),
        verifiedHRCFuseR1R2Row(rating: "40A", activeSize: "6.0", earthSize: "2.5", disconnectionTime: .s0_4, maxRphe: 0.6, maxRe: 0.4),
        verifiedHRCFuseR1R2Row(rating: "40A", activeSize: "6.0", earthSize: "2.5", disconnectionTime: .s5_0, maxRphe: 1.0, maxRe: 0.7),
        verifiedHRCFuseR1R2Row(rating: "50A", activeSize: "10.0", earthSize: "4.0", disconnectionTime: .s0_4, maxRphe: 0.5, maxRe: 0.3),
        verifiedHRCFuseR1R2Row(rating: "50A", activeSize: "10.0", earthSize: "4.0", disconnectionTime: .s5_0, maxRphe: 0.8, maxRe: 0.6),
        verifiedHRCFuseR1R2Row(rating: "63A", activeSize: "16.0", earthSize: "6.0", disconnectionTime: .s0_4, maxRphe: 0.4, maxRe: 0.3),
        verifiedHRCFuseR1R2Row(rating: "63A", activeSize: "16.0", earthSize: "6.0", disconnectionTime: .s5_0, maxRphe: 0.6, maxRe: 0.4)
    ]

    static let rows = table8_1Rows

    private static let lookupByKey: [ZsLookupKey: ZsLookupRow] = {
        var lookup = [ZsLookupKey: ZsLookupRow]()

        for row in rows {
            assert(lookup[row.key] == nil, "Duplicate Zs lookup key found for \(row.referenceLabel)")
            lookup[row.key] = row
        }

        return lookup
    }()

    private static let r1r2LookupByKey: [R1R2LookupKey: R1R2LookupRow] = {
        var lookup = [R1R2LookupKey: R1R2LookupRow]()

        for row in table8_2Rows {
            assert(lookup[row.key] == nil, "Duplicate Table 8.2 lookup key found for \(row.sourceLabel)")
            lookup[row.key] = row
        }

        return lookup
    }()

    static func hasVerifiedRows(for method: ZsTestMethod) -> Bool {
        switch method {
        case .zs:
            return rows.contains { $0.method == method && $0.isVerified }
        case .r1PlusR2:
            return table8_2Rows.contains { $0.isVerified }
        }
    }

    static func lookupRow(for key: ZsLookupKey) -> ZsLookupRow? {
        lookupByKey[key]
    }

    static func lookupR1R2Row(for key: R1R2LookupKey) -> R1R2LookupRow? {
        r1r2LookupByKey[key]
    }

    private static func verifiedMCBRows(
        curve: ZsTripCurve,
        values: [(String, Double)]
    ) -> [ZsLookupRow] {
        values.map { rating, maxAllowedZs in
            ZsLookupRow(
                table: .table8_1,
                method: .zs,
                deviceType: .mcb,
                rating: rating,
                curve: curve,
                voltage: .v230,
                disconnectionTime: .s0_4,
                maxAllowedZs: maxAllowedZs,
                referenceLabel: ZsReferenceSourceTable.table8_1.verifiedLabel,
                isVerified: true
            )
        }
    }

    private static func verifiedR1R2Rows(
        rating: String,
        activeSize: String,
        earthSize: String,
        typeB: (Double, Double),
        typeC: (Double, Double),
        typeD: (Double, Double)
    ) -> [R1R2LookupRow] {
        [
            R1R2LookupRow(
                deviceType: .mcb,
                ratingAmps: rating,
                activeSizeMM2: activeSize,
                earthSizeMM2: earthSize,
                breakerCurve: .typeB,
                systemVoltage: .v230,
                disconnectionTime: .s0_4,
                maxRphe: typeB.0,
                maxRe: typeB.1,
                sourceLabel: ZsReferenceSourceTable.table8_2.verifiedLabel,
                isVerified: true
            ),
            R1R2LookupRow(
                deviceType: .mcb,
                ratingAmps: rating,
                activeSizeMM2: activeSize,
                earthSizeMM2: earthSize,
                breakerCurve: .typeC,
                systemVoltage: .v230,
                disconnectionTime: .s0_4,
                maxRphe: typeC.0,
                maxRe: typeC.1,
                sourceLabel: ZsReferenceSourceTable.table8_2.verifiedLabel,
                isVerified: true
            ),
            R1R2LookupRow(
                deviceType: .mcb,
                ratingAmps: rating,
                activeSizeMM2: activeSize,
                earthSizeMM2: earthSize,
                breakerCurve: .typeD,
                systemVoltage: .v230,
                disconnectionTime: .s0_4,
                maxRphe: typeD.0,
                maxRe: typeD.1,
                sourceLabel: ZsReferenceSourceTable.table8_2.verifiedLabel,
                isVerified: true
            )
        ]
    }

    private static func verifiedHRCFuseR1R2Row(
        rating: String,
        activeSize: String,
        earthSize: String,
        disconnectionTime: ZsDisconnectionTime,
        maxRphe: Double,
        maxRe: Double
    ) -> R1R2LookupRow {
        R1R2LookupRow(
            deviceType: .hrcFuse,
            ratingAmps: rating,
            activeSizeMM2: activeSize,
            earthSizeMM2: earthSize,
            breakerCurve: nil,
            systemVoltage: .v230,
            disconnectionTime: disconnectionTime,
            maxRphe: maxRphe,
            maxRe: maxRe,
            sourceLabel: ZsReferenceSourceTable.table8_2.verifiedLabel,
            isVerified: true
        )
    }
}

private enum ZsChecker {
    static func evaluate(
        measuredText: String,
        protectionState: ProtectionInputState,
        testMethod: ZsTestMethod,
        systemVoltage: ZsSystemVoltage,
        disconnectionTime: ZsDisconnectionTime,
        activeConductorSizeText: String,
        earthConductorSizeText: String
    ) -> ZsCheckResult {
        let measuredZs = measuredText.numericDoubleValue.flatMap { $0 >= 0 ? $0 : nil }
        let assumptionsUsed = assumptionsText(
            protectionState: protectionState,
            testMethod: testMethod,
            systemVoltage: systemVoltage,
            disconnectionTime: disconnectionTime,
            activeConductorSizeText: activeConductorSizeText,
            earthConductorSizeText: earthConductorSizeText
        )

        if testMethod == .r1PlusR2 {
            return evaluateR1R2(
                measuredZs: measuredZs,
                protectionState: protectionState,
                systemVoltage: systemVoltage,
                disconnectionTime: disconnectionTime,
                activeConductorSizeText: activeConductorSizeText,
                earthConductorSizeText: earthConductorSizeText,
                assumptionsUsed: assumptionsUsed
            )
        }

        return evaluateZs(
            measuredZs: measuredZs,
            protectionState: protectionState,
            testMethod: testMethod,
            systemVoltage: systemVoltage,
            disconnectionTime: disconnectionTime,
            assumptionsUsed: assumptionsUsed
        )
    }

    private static func evaluateZs(
        measuredZs: Double?,
        protectionState: ProtectionInputState,
        testMethod: ZsTestMethod,
        systemVoltage: ZsSystemVoltage,
        disconnectionTime: ZsDisconnectionTime,
        assumptionsUsed: String
    ) -> ZsCheckResult {
        var missingFields = [ZsMissingField]()
        if measuredZs == nil {
            missingFields.append(.measuredZs)
        }
        if protectionState.protectionDeviceType == "Not Set" {
            missingFields.append(.protectiveDeviceType)
        }
        if protectionState.selectedProtectionSize == "Not Set" {
            missingFields.append(.protectiveDeviceRating)
        }
        if protectionState.requiresCurveForStrictZsLookup && protectionState.protectionCurve == "Not Set" {
            missingFields.append(.curve)
        }
        if systemVoltage == .notSet {
            missingFields.append(.voltage)
        }
        if disconnectionTime == .notSet {
            missingFields.append(.disconnectionTime)
        }

        if !missingFields.isEmpty {
            let missingList = missingFields.map(\.label).joined(separator: ", ")
            return ZsCheckResult(
                method: .zs,
                measuredZs: measuredZs,
                maxAllowedZs: nil,
                maxRphe: nil,
                maxRe: nil,
                margin: nil,
                outcome: .reviewRequired,
                confidence: .reviewRequired,
                assumptionsUsed: assumptionsUsed,
                message: "Review required. Missing: \(missingList)"
            )
        }

        if let reviewReason = protectionState.reviewRequiredReason(for: .zs) {
            return ZsCheckResult(
                method: .zs,
                measuredZs: measuredZs,
                maxAllowedZs: nil,
                maxRphe: nil,
                maxRe: nil,
                margin: nil,
                outcome: .reviewRequired,
                confidence: .reviewRequired,
                assumptionsUsed: assumptionsUsed,
                message: reviewReason
            )
        }

        guard
            let measuredZs,
            let curve = protectionState.zsLookupCurve
        else {
            return ZsCheckResult(
                method: .zs,
                measuredZs: measuredZs,
                maxAllowedZs: nil,
                maxRphe: nil,
                maxRe: nil,
                margin: nil,
                outcome: .reviewRequired,
                confidence: .reviewRequired,
                assumptionsUsed: assumptionsUsed,
                message: "Review required. Breaker type not supported for automatic check."
            )
        }

        let deviceType: ZsLookupDeviceType
        switch protectionState.protectionDeviceType {
        case "MCB", "RCBO":
            deviceType = .mcb
        default:
            return ZsCheckResult(
                method: .zs,
                measuredZs: measuredZs,
                maxAllowedZs: nil,
                maxRphe: nil,
                maxRe: nil,
                margin: nil,
                outcome: .reviewRequired,
                confidence: .reviewRequired,
                assumptionsUsed: assumptionsUsed,
                message: "Review required. Breaker type not supported for automatic check."
            )
        }

        let lookupKey = ZsLookupKey(
            method: testMethod,
            deviceType: deviceType,
            rating: protectionState.selectedProtectionSize,
            curve: curve,
            systemVoltage: systemVoltage,
            disconnectionTime: disconnectionTime
        )

        guard let row = ZsReferenceTable.lookupRow(for: lookupKey) else {
            let tableLabel = testMethod.referenceTable.standardLabel
            let message = ZsReferenceTable.hasVerifiedRows(for: testMethod)
                ? "Review required. No verified \(tableLabel) row is loaded in the app for the selected inputs."
                : "Review required. No verified \(tableLabel) rows are currently loaded in the app for \(testMethod.assumptionsLabel)."

            return ZsCheckResult(
                method: .zs,
                measuredZs: measuredZs,
                maxAllowedZs: nil,
                maxRphe: nil,
                maxRe: nil,
                margin: nil,
                outcome: .reviewRequired,
                confidence: .reviewRequired,
                assumptionsUsed: assumptionsUsed,
                message: message
            )
        }

        guard row.isVerified else {
            return ZsCheckResult(
                method: .zs,
                measuredZs: measuredZs,
                maxAllowedZs: nil,
                maxRphe: nil,
                maxRe: nil,
                margin: nil,
                outcome: .reviewRequired,
                confidence: .reviewRequired,
                assumptionsUsed: assumptionsUsed + " • Reference: \(row.referenceLabel)",
                message: "Review required. The matched in-app row is not verified and cannot be used for PASS/FAIL."
            )
        }

        let margin = row.maxAllowedZs - measuredZs
        let outcome: ZsCheckOutcome = measuredZs <= row.maxAllowedZs ? .pass : .fail
        let message = outcome == .pass
            ? "Exact verified \(row.referenceLabel) match found for the selected inputs."
            : "Measured Zs exceeds the exact verified \(row.referenceLabel) limit for the selected inputs."

        return ZsCheckResult(
            method: .zs,
            measuredZs: measuredZs,
            maxAllowedZs: row.maxAllowedZs,
            maxRphe: nil,
            maxRe: nil,
            margin: margin,
            outcome: outcome,
            confidence: .high,
            assumptionsUsed: assumptionsUsed + " • Reference: \(row.referenceLabel)",
            message: message
        )
    }

    private static func evaluateR1R2(
        measuredZs: Double?,
        protectionState: ProtectionInputState,
        systemVoltage: ZsSystemVoltage,
        disconnectionTime: ZsDisconnectionTime,
        activeConductorSizeText: String,
        earthConductorSizeText: String,
        assumptionsUsed: String
    ) -> ZsCheckResult {
        let activeInput = activeConductorSizeText.normalizedFieldValue
        let earthInput = earthConductorSizeText.normalizedFieldValue
        let activeSizeKey = R1R2ConductorSizeSelection.lookupKey(for: activeConductorSizeText)
        let earthSizeKey = R1R2ConductorSizeSelection.lookupKey(for: earthConductorSizeText)

        var missingFields = [ZsMissingField]()
        if measuredZs == nil {
            missingFields.append(.measuredZs)
        }
        if protectionState.protectionDeviceType == "Not Set" {
            missingFields.append(.protectiveDeviceType)
        }
        if protectionState.selectedProtectionSize == "Not Set" {
            missingFields.append(.protectiveDeviceRating)
        }
        if protectionState.requiresCurveForStrictZsLookup && protectionState.protectionCurve == "Not Set" {
            missingFields.append(.curve)
        }
        if systemVoltage == .notSet {
            missingFields.append(.voltage)
        }
        if disconnectionTime == .notSet {
            missingFields.append(.disconnectionTime)
        }
        if activeInput.isEmpty {
            missingFields.append(.activeConductorSize)
        }
        if earthInput.isEmpty {
            missingFields.append(.earthConductorSize)
        }

        if !missingFields.isEmpty {
            let missingList = missingFields.map(\.label).joined(separator: ", ")
            return ZsCheckResult(
                method: .r1PlusR2,
                measuredZs: measuredZs,
                maxAllowedZs: nil,
                maxRphe: nil,
                maxRe: nil,
                margin: nil,
                outcome: .reviewRequired,
                confidence: .reviewRequired,
                assumptionsUsed: assumptionsUsed,
                message: "Review required. Missing: \(missingList)"
            )
        }

        if let reviewReason = protectionState.reviewRequiredReason(for: .r1PlusR2) {
            return ZsCheckResult(
                method: .r1PlusR2,
                measuredZs: measuredZs,
                maxAllowedZs: nil,
                maxRphe: nil,
                maxRe: nil,
                margin: nil,
                outcome: .reviewRequired,
                confidence: .reviewRequired,
                assumptionsUsed: assumptionsUsed,
                message: reviewReason
            )
        }

        if activeSizeKey == nil || earthSizeKey == nil {
            return ZsCheckResult(
                method: .r1PlusR2,
                measuredZs: measuredZs,
                maxAllowedZs: nil,
                maxRphe: nil,
                maxRe: nil,
                margin: nil,
                outcome: .reviewRequired,
                confidence: .reviewRequired,
                assumptionsUsed: assumptionsUsed,
                message: "Review required. The conductor size entry is outside the verified Table 8.2 lookup."
            )
        }

        guard
            let measuredZs,
            let activeSizeKey,
            let earthSizeKey
        else {
            return ZsCheckResult(
                method: .r1PlusR2,
                measuredZs: measuredZs,
                maxAllowedZs: nil,
                maxRphe: nil,
                maxRe: nil,
                margin: nil,
                outcome: .reviewRequired,
                confidence: .reviewRequired,
                assumptionsUsed: assumptionsUsed,
                message: "Review required. The protection or conductor details are not specific enough for a strict Table 8.2 lookup."
            )
        }

        let deviceType: ZsLookupDeviceType
        let curve: ZsTripCurve?
        switch protectionState.protectionDeviceType {
        case "MCB", "RCBO":
            guard let lookupCurve = protectionState.zsLookupCurve else {
                return ZsCheckResult(
                    method: .r1PlusR2,
                    measuredZs: measuredZs,
                    maxAllowedZs: nil,
                    maxRphe: nil,
                    maxRe: nil,
                    margin: nil,
                    outcome: .reviewRequired,
                    confidence: .reviewRequired,
                    assumptionsUsed: assumptionsUsed,
                    message: "Review required. Missing: curve"
                )
            }
            deviceType = .mcb
            curve = lookupCurve
        case "HRC Fuse":
            deviceType = .hrcFuse
            curve = nil
        default:
            return ZsCheckResult(
                method: .r1PlusR2,
                measuredZs: measuredZs,
                maxAllowedZs: nil,
                maxRphe: nil,
                maxRe: nil,
                margin: nil,
                outcome: .reviewRequired,
                confidence: .reviewRequired,
                assumptionsUsed: assumptionsUsed,
                message: "Review required. Breaker type not supported for automatic check."
            )
        }

        let lookupKey = R1R2LookupKey(
            deviceType: deviceType,
            ratingAmps: protectionState.selectedProtectionSize,
            activeSizeMM2: activeSizeKey,
            earthSizeMM2: earthSizeKey,
            breakerCurve: curve,
            systemVoltage: systemVoltage,
            disconnectionTime: disconnectionTime
        )

        guard let row = ZsReferenceTable.lookupR1R2Row(for: lookupKey) else {
            let tableLabel = ZsReferenceSourceTable.table8_2.standardLabel
            let message = ZsReferenceTable.hasVerifiedRows(for: .r1PlusR2)
                ? "Review required. No verified \(tableLabel) row is loaded in the app for the selected inputs."
                : "Review required. No verified \(tableLabel) rows are currently loaded in the app for R1+R2 (Table 8.2)."

            return ZsCheckResult(
                method: .r1PlusR2,
                measuredZs: measuredZs,
                maxAllowedZs: nil,
                maxRphe: nil,
                maxRe: nil,
                margin: nil,
                outcome: .reviewRequired,
                confidence: .reviewRequired,
                assumptionsUsed: assumptionsUsed,
                message: message
            )
        }

        guard row.isVerified else {
            return ZsCheckResult(
                method: .r1PlusR2,
                measuredZs: measuredZs,
                maxAllowedZs: nil,
                maxRphe: nil,
                maxRe: nil,
                margin: nil,
                outcome: .reviewRequired,
                confidence: .reviewRequired,
                assumptionsUsed: assumptionsUsed + " • Reference: \(row.sourceLabel)",
                message: "Review required. The matched in-app row is not verified and cannot be used for PASS/FAIL."
            )
        }

        let maxR1R2 = row.maxR1R2
        let margin = maxR1R2 - measuredZs
        let outcome: ZsCheckOutcome = measuredZs <= maxR1R2 ? .pass : .fail
        let message = outcome == .pass
            ? "Exact verified \(row.sourceLabel) match found for the selected inputs."
            : "Measured R1+R2 exceeds the exact verified \(row.sourceLabel) limit for the selected inputs."

        return ZsCheckResult(
            method: .r1PlusR2,
            measuredZs: measuredZs,
            maxAllowedZs: maxR1R2,
            maxRphe: row.maxRphe,
            maxRe: row.maxRe,
            margin: margin,
            outcome: outcome,
            confidence: .high,
            assumptionsUsed: assumptionsUsed + " • Reference: \(row.sourceLabel)",
            message: message
        )
    }

    private static func assumptionsText(
        protectionState: ProtectionInputState,
        testMethod: ZsTestMethod,
        systemVoltage: ZsSystemVoltage,
        disconnectionTime: ZsDisconnectionTime,
        activeConductorSizeText: String,
        earthConductorSizeText: String
    ) -> String {
        if protectionState.protectionDeviceType == "Main Isolator" {
            return "Protection: \(protectionState.summary) • Record only • Upstream protection to verify"
        }

        let protectionSummary = protectionState.summary.isEmpty ? "Not set" : protectionState.summary
        var parts = [
            "Method: \(testMethod.assumptionsLabel)",
            "Protection: \(protectionSummary)",
            "Voltage: \(systemVoltage.label)",
            "Disconnection Time: \(disconnectionTime.label)"
        ]

        if protectionState.protectionDeviceType == "RCBO" {
            let tableLabel = testMethod == .r1PlusR2 ? "Table 8.2" : "Table 8.1"
            parts.append("Lookup Basis: RCBO treated as equivalent MCB for \(tableLabel)")
        }

        if testMethod == .r1PlusR2 {
            parts.append("Active: \(R1R2ConductorSizeSelection.label(for: activeConductorSizeText))")
            parts.append("Earth: \(R1R2ConductorSizeSelection.label(for: earthConductorSizeText))")
        }

        return parts.joined(separator: " • ")
    }
}

struct FaultLoopExportContext {
    let method: String
    let tableLabel: String
    let measuredValue: String
    let resultTitle: String
    let voltage: String
    let disconnectionTime: String
    let activeConductorSize: String?
    let earthConductorSize: String?
    let maxAllowedValue: Double?

    var isR1R2: Bool {
        method == ZsTestMethod.r1PlusR2.rawValue
    }
}

enum FaultLoopExportContextBuilder {
    static func build(for result: TestResult) -> FaultLoopExportContext {
        if result.isMainIsolator {
            return FaultLoopExportContext(
                method: "Record Only",
                tableLabel: "--",
                measuredValue: result.mainIsolatorFaultLoopSummary,
                resultTitle: "Review Required",
                voltage: "--",
                disconnectionTime: "--",
                activeConductorSize: nil,
                earthConductorSize: nil,
                maxAllowedValue: nil
            )
        }

        let testMethod = ZsTestMethod(rawValue: result.testMethod.normalizedFieldValue) ?? .zs
        let systemVoltage = ZsSystemVoltage(rawValue: result.systemVoltage.normalizedFieldValue) ?? .v230
        let disconnectionTime = ZsDisconnectionTime(rawValue: result.disconnectionTime.normalizedFieldValue) ?? .s0_4
        let protectionState = ProtectionInputState.parse(result.protectionSizeType)
        let checkResult = ZsChecker.evaluate(
            measuredText: result.faultLoopImpedance,
            protectionState: protectionState,
            testMethod: testMethod,
            systemVoltage: systemVoltage,
            disconnectionTime: disconnectionTime,
            activeConductorSizeText: result.cableSize,
            earthConductorSizeText: result.earthConductorSize
        )

        return FaultLoopExportContext(
            method: testMethod.rawValue,
            tableLabel: testMethod.referenceTable.rawValue,
            measuredValue: result.faultLoopImpedance.normalizedFieldValue,
            resultTitle: checkResult.outcome.title,
            voltage: systemVoltage.label,
            disconnectionTime: disconnectionTime.label,
            activeConductorSize: testMethod == .r1PlusR2 ? R1R2ConductorSizeSelection.lookupKey(for: result.cableSize) : nil,
            earthConductorSize: testMethod == .r1PlusR2 ? R1R2ConductorSizeSelection.lookupKey(for: result.earthConductorSize) : nil,
            maxAllowedValue: checkResult.maxAllowedZs
        )
    }
}

private struct ZsCheckSummaryCard: View {
    let result: ZsCheckResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: result.outcome.icon)
                    .foregroundColor(result.outcome.tint)
                Text(result.method == .r1PlusR2 ? "R1+R2 Check Summary" : "Zs Check Summary")
                    .font(.caption.bold())
                    .foregroundColor(result.outcome.tint)
            }

            ZsSummaryRow(title: result.method == .r1PlusR2 ? "Measured R1+R2" : "Measured Zs", value: displayValue(for: result.measuredZs))
            if result.method == .r1PlusR2 {
                ZsSummaryRow(title: "Max Rphe", value: displayValue(for: result.maxRphe))
                ZsSummaryRow(title: "Max Re", value: displayValue(for: result.maxRe))
                ZsSummaryRow(title: "Max R1+R2", value: displayValue(for: result.maxAllowedZs))
            } else {
                ZsSummaryRow(title: "Max Allowed Zs", value: displayValue(for: result.maxAllowedZs))
            }
            ZsSummaryRow(title: "Margin", value: displayMargin(for: result.margin))
            ZsSummaryRow(title: "Result", value: result.outcome.title, valueColor: result.outcome.tint)
            ZsSummaryRow(title: "Confidence", value: result.confidence.title, valueColor: result.confidence.tint)

            VStack(alignment: .leading, spacing: 4) {
                Text("Assumptions Used")
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                Text(result.assumptionsUsed)
                    .font(.caption)
                    .foregroundColor(.primary)
            }

            Text(result.message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(result.outcome.tint.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(result.outcome.tint.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func displayValue(for value: Double?) -> String {
        guard let value else { return "--" }

        if value >= 1 {
            return String(format: "%.2f Ω", value)
        }

        return String(format: "%.3f Ω", value)
    }

    private func displayMargin(for margin: Double?) -> String {
        guard let margin else { return "--" }

        if abs(margin) >= 1 {
            return String(format: "%+.2f Ω", margin)
        }

        return String(format: "%+.3f Ω", margin)
    }
}

private struct MainIsolatorZsSummaryCard: View {
    let supplyType: MainIsolatorSupplyType
    let activeZs: String
    let phaseAZs: String
    let phaseBZs: String
    let phaseCZs: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Zs Check Summary")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
            }

            if supplyType == .threePhase {
                ZsSummaryRow(title: "A Phase Zs", value: displayText(for: phaseAZs, prefix: "A"))
                ZsSummaryRow(title: "B Phase Zs", value: displayText(for: phaseBZs, prefix: "B"))
                ZsSummaryRow(title: "C Phase Zs", value: displayText(for: phaseCZs, prefix: "C"))
            } else {
                ZsSummaryRow(title: "Measured Zs", value: displayText(for: activeZs, prefix: "Active"))
            }

            ZsSummaryRow(title: "Max Allowed Zs", value: "--")
            ZsSummaryRow(title: "Margin", value: "--")
            ZsSummaryRow(title: "Result", value: "Review Required", valueColor: .orange)
            ZsSummaryRow(title: "Confidence", value: "Review Required", valueColor: .orange)

            Text("Record only.\nUpstream protection to verify.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.orange.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func displayText(for value: String, prefix: String) -> String {
        let trimmedValue = value.normalizedFieldValue
        guard !trimmedValue.isEmpty else { return "--" }
        return "\(prefix): \(trimmedValue) Ω"
    }
}

private struct ZsSummaryRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.primary)
            Spacer(minLength: 12)
            Text(value)
                .font(.caption)
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct PolarityHelperField: View {
    @Binding var value: String
    var errorMessage: String? = nil
    @State private var state = PolarityInputState()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Polarity Test Equipment / Circuit")
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            Text("Use the checklist to guide the polarity check, then confirm the final pass/fail result.")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(PolarityInputState.CheckItem.allCases) { item in
                VisualInspectionChecklistRow(
                    title: item.title,
                    selection: binding(for: item)
                )
            }

            if let suggestion = state.suggestedResult {
                HStack(spacing: 10) {
                    Text("Suggested outcome:")
                        .font(.caption.bold())
                        .foregroundColor(.primary)

                    Text(suggestion)
                        .font(.caption.bold())
                        .foregroundColor(suggestion == "Pass" ? .green : .red)

                    Spacer()

                    if suggestion != state.result {
                        Button("Use Suggested") {
                            state.result = suggestion
                        }
                        .font(.caption.bold())
                    }
                }
                .padding(10)
                .background(Color.npFieldSurface)
                .cornerRadius(10)
            } else {
                Text("Complete each polarity check to generate a suggested outcome.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Picker("Polarity Result", selection: $state.result) {
                Text("Not Set").tag("")
                Text("Pass").tag("Pass")
                Text("Fail").tag("Fail")
            }
            .pickerStyle(.segmented)

            if !state.result.isEmpty {
                Text("Saved as: \(state.result)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                InlineValidationText(message: errorMessage)
            }
        }
        .onAppear {
            state = PolarityInputState.parse(value)
        }
        .onChange(of: state) { _, newState in
            let newValue = newState.result.normalizedFieldValue
            if value != newValue {
                value = newValue
            }
        }
        .onChange(of: value) { _, newValue in
            let parsedState = PolarityInputState.parse(newValue)
            if parsedState.result != state.result {
                state.result = parsedState.result
            }
        }
    }

    private func binding(for item: PolarityInputState.CheckItem) -> Binding<VisualInspectionCheckStatus> {
        Binding(
            get: { state.statuses[item] ?? .notChecked },
            set: { newValue in
                state.statuses[item] = newValue
            }
        )
    }
}

private struct PolarityInputState: Equatable {
    enum CheckItem: String, CaseIterable, Identifiable {
        case activeSwitching
        case outletConnection
        case identification

        var id: String { rawValue }

        var title: String {
            switch self {
            case .activeSwitching:
                return "Active conductor is correctly switched and protected"
            case .outletConnection:
                return "Socket-outlets and accessories show correct polarity"
            case .identification:
                return "Conductors and terminations align with the intended polarity"
            }
        }
    }

    var result = ""
    var statuses: [CheckItem: VisualInspectionCheckStatus] = Dictionary(
        uniqueKeysWithValues: CheckItem.allCases.map { ($0, .notChecked) }
    )

    var suggestedResult: String? {
        let allStatuses = CheckItem.allCases.map { statuses[$0] ?? .notChecked }

        if allStatuses.contains(.issue) {
            return "Fail"
        }

        if allStatuses.allSatisfy({ $0 == .ok }) {
            return "Pass"
        }

        return nil
    }

    static func parse(_ rawValue: String) -> PolarityInputState {
        var state = PolarityInputState()
        let normalized = rawValue.normalizedFieldValue

        if normalized.caseInsensitiveCompare("Pass") == .orderedSame {
            state.result = "Pass"
        } else if normalized.caseInsensitiveCompare("Fail") == .orderedSame {
            state.result = "Fail"
        }

        return state
    }
}

private struct VisualInspectionHelperField: View {
    @Binding var value: String
    var errorMessage: String? = nil
    @State private var state = VisualInspectionInputState()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visual Inspection")
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            Text("Work through the quick checklist below, then confirm the final visual inspection result.")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(VisualInspectionInputState.CheckItem.allCases) { item in
                VisualInspectionChecklistRow(
                    title: item.title,
                    selection: binding(for: item)
                )
            }

            if let suggestion = state.suggestedResult {
                HStack(spacing: 10) {
                    Text("Suggested outcome:")
                        .font(.caption.bold())
                        .foregroundColor(.primary)

                    Text(suggestion)
                        .font(.caption.bold())
                        .foregroundColor(suggestion == "Pass" ? .green : .red)

                    Spacer()

                    if suggestion != state.result {
                        Button("Use Suggested") {
                            state.result = suggestion
                        }
                        .font(.caption.bold())
                    }
                }
                .padding(10)
                .background(Color.npFieldSurface)
                .cornerRadius(10)
            } else {
                Text("Complete each checklist item to generate a suggested outcome.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Picker("Visual Inspection Result", selection: $state.result) {
                Text("Not Set").tag("")
                Text("Pass").tag("Pass")
                Text("Fail").tag("Fail")
            }
            .pickerStyle(.segmented)

            if !state.result.isEmpty {
                Text("Saved as: \(state.result)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                InlineValidationText(message: errorMessage)
            }
        }
        .onAppear {
            state = VisualInspectionInputState.parse(value)
        }
        .onChange(of: state) { _, newState in
            let newValue = newState.result.normalizedFieldValue
            if value != newValue {
                value = newValue
            }
        }
        .onChange(of: value) { _, newValue in
            let parsedState = VisualInspectionInputState.parse(newValue)
            if parsedState.result != state.result {
                state.result = parsedState.result
            }
        }
    }

    private func binding(for item: VisualInspectionInputState.CheckItem) -> Binding<VisualInspectionCheckStatus> {
        Binding(
            get: { state.statuses[item] ?? .notChecked },
            set: { newValue in
                state.statuses[item] = newValue
            }
        )
    }
}

private struct VisualInspectionChecklistRow: View {
    let title: String
    @Binding var selection: VisualInspectionCheckStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)

            Picker(title, selection: $selection) {
                ForEach(VisualInspectionCheckStatus.allCases) { status in
                    Text(status.label).tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(12)
        .background(Color.npFieldSurface)
        .cornerRadius(12)
    }
}

private enum VisualInspectionCheckStatus: String, CaseIterable, Identifiable {
    case notChecked
    case ok
    case issue

    var id: String { rawValue }

    var label: String {
        switch self {
        case .notChecked:
            return "Unset"
        case .ok:
            return "OK"
        case .issue:
            return "Issue"
        }
    }
}

private struct VisualInspectionInputState: Equatable {
    enum CheckItem: String, CaseIterable, Identifiable {
        case damage
        case secure
        case terminations
        case identification

        var id: String { rawValue }

        var title: String {
            switch self {
            case .damage:
                return "No visible damage to equipment, accessories, or cabling"
            case .secure:
                return "Equipment and wiring are secure and adequately supported"
            case .terminations:
                return "Terminations, enclosures, and protection appear correct"
            case .identification:
                return "Labels, barriers, and circuit identification are acceptable"
            }
        }
    }

    var result = ""
    var statuses: [CheckItem: VisualInspectionCheckStatus] = Dictionary(
        uniqueKeysWithValues: CheckItem.allCases.map { ($0, .notChecked) }
    )

    var suggestedResult: String? {
        let allStatuses = CheckItem.allCases.map { statuses[$0] ?? .notChecked }

        if allStatuses.contains(.issue) {
            return "Fail"
        }

        if allStatuses.allSatisfy({ $0 == .ok }) {
            return "Pass"
        }

        return nil
    }

    static func parse(_ rawValue: String) -> VisualInspectionInputState {
        var state = VisualInspectionInputState()
        let normalized = rawValue.normalizedFieldValue

        if normalized.caseInsensitiveCompare("Pass") == .orderedSame {
            state.result = "Pass"
        } else if normalized.caseInsensitiveCompare("Fail") == .orderedSame {
            state.result = "Fail"
        }

        return state
    }
}

private struct StructuredProtectionField: View {
    @Binding var value: String
    var errorMessage: String? = nil
    @State private var state = ProtectionInputState()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Protection Size and Type")
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            HStack(spacing: 10) {
                Menu {
                    ForEach(ProtectionInputState.protectionSizes, id: \.self) { size in
                        Button(size) {
                            state.selectedProtectionSize = size
                        }
                    }
                } label: {
                    selectionMenuLabel(
                        title: state.protectionSizeLabel,
                        isPlaceholder: state.selectedProtectionSize == "Not Set",
                        showsError: errorMessage != nil
                    )
                }

                Menu {
                    ForEach(ProtectionInputState.deviceTypeOptions, id: \.self) { deviceType in
                        Button(deviceType) {
                            state.protectionDeviceType = deviceType
                            if deviceType != "MCB" && deviceType != "RCBO" {
                                state.protectionCurve = "Not Set"
                            }
                        }
                    }
                } label: {
                    selectionMenuLabel(
                        title: state.protectionDeviceLabel,
                        isPlaceholder: state.protectionDeviceType == "Not Set",
                        showsError: errorMessage != nil
                    )
                }
            }

            if state.showsCurveSelection {
                Menu {
                    ForEach(ProtectionInputState.curveOptions, id: \.self) { option in
                        Button(option) {
                            state.protectionCurve = option
                        }
                    }
                } label: {
                    selectionMenuLabel(
                        title: state.curveLabel,
                        isPlaceholder: state.protectionCurve == "Not Set",
                        showsError: false
                    )
                }
            }

            if state.showsCustomDetails {
                EntryTextField(
                    title: "Custom Protection Details",
                    placeholder: "e.g. 125A MCCB, gG fuse",
                    text: $state.customDetails,
                    helperText: "Use this when the rating or device type is outside the common options."
                )
            }

            Text(state.guidanceText)
                .font(.caption)
                .foregroundColor(.secondary)

            if !state.summary.isEmpty {
                Text("Saved as: \(state.summary)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let errorMessage {
                InlineValidationText(message: errorMessage)
            }
        }
        .onAppear {
            state = ProtectionInputState.parse(value)
        }
        .onChange(of: state) { _, newState in
            let newValue = newState.summary
            if value != newValue {
                value = newValue
            }
        }
        .onChange(of: value) { _, newValue in
            let parsedState = ProtectionInputState.parse(newValue)
            if parsedState != state {
                state = parsedState
            }
        }
    }

    private func selectionMenuLabel(title: String, isPlaceholder: Bool, showsError: Bool) -> some View {
        HStack {
            Text(title)
                .foregroundColor(isPlaceholder ? .secondary : .primary)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.npFieldSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(showsError ? .red : Color(uiColor: .separator), lineWidth: 1)
        )
        .cornerRadius(10)
    }
}

private struct ProtectionInputState: Equatable {
    static let protectionSizes = [
        "Not Set",
        "6A",
        "10A",
        "16A",
        "20A",
        "25A",
        "32A",
        "40A",
        "50A",
        "63A",
        "80A",
        "100A",
        "125A",
        "160A",
        "200A",
        "250A"
    ]
    static let deviceTypeOptions = ["Not Set", "MCB", "RCBO", "HRC Fuse", "Fuse / Rewirable Fuse", "MCCB", "Main Isolator", "Other"]
    static let curveOptions = ["Not Set", "Type B", "Type C", "Type D"]

    var selectedProtectionSize = "Not Set"
    var protectionDeviceType = "Not Set"
    var protectionCurve = "Not Set"
    var customDetails = ""

    var protectionSizeLabel: String {
        selectedProtectionSize == "Not Set" ? "Select Rating" : selectedProtectionSize
    }

    var protectionDeviceLabel: String {
        protectionDeviceType == "Not Set" ? "Select Device" : protectionDeviceType
    }

    var curveLabel: String {
        protectionCurve == "Not Set" ? "Select Curve" : protectionCurve
    }

    var showsCustomDetails: Bool {
        protectionDeviceType == "Other"
    }

    var isMainIsolator: Bool {
        protectionDeviceType == "Main Isolator"
    }

    var showsCurveSelection: Bool {
        protectionDeviceType == "MCB" || protectionDeviceType == "RCBO"
    }

    var requiresCurveForLoopGuidance: Bool {
        protectionDeviceType == "MCB" || protectionDeviceType == "RCBO"
    }

    var requiresCurveForStrictZsLookup: Bool {
        protectionDeviceType == "MCB" || protectionDeviceType == "RCBO"
    }

    var zsLookupDeviceType: ZsLookupDeviceType? {
        switch protectionDeviceType {
        case "MCB":
            return .mcb
        case "RCBO":
            return .rcbo
        case "HRC Fuse":
            return .hrcFuse
        default:
            return nil
        }
    }

    var zsLookupCurve: ZsTripCurve? {
        switch protectionCurve {
        case "Type B":
            return .typeB
        case "Type C":
            return .typeC
        case "Type D":
            return .typeD
        default:
            return nil
        }
    }

    func reviewRequiredReason(for method: ZsTestMethod) -> String? {
        switch protectionDeviceType {
        case "Fuse / Rewirable Fuse":
            return "Review required. Fuse type requires verified reference data before automatic PASS/FAIL."
        case "HRC Fuse":
            if method == .r1PlusR2 {
                return nil
            }
            return "Review required. HRC fuse protection requires verified Table 8.1 reference data before automatic PASS/FAIL."
        case "MCCB":
            return "Review required. MCCB protection requires manual verification."
        case "Main Isolator":
            return nil
        case "Other":
            return "Review required. Breaker type not supported for automatic check."
        case "RCBO":
            return nil
        default:
            return nil
        }
    }

    var loopReferenceLabel: String? {
        guard selectedProtectionSize != "Not Set" else { return nil }
        guard requiresCurveForLoopGuidance, protectionCurve != "Not Set" else { return nil }
        return "\(selectedProtectionSize) \(protectionDeviceType) \(protectionCurve)"
    }

    var loopGuidanceMessage: String {
        if protectionDeviceType == "Other" {
            return "The protection entry uses custom details (\(summary)). Confirm the exact device characteristic and the matching AS/NZS 3000 reference table before deciding pass or fail."
        }

        if protectionDeviceType == "RCBO" || protectionDeviceType == "HRC Fuse" || protectionDeviceType == "Fuse / Rewirable Fuse" || protectionDeviceType == "MCCB" {
            return "Protection is recorded as \(summary). Use the exact device characteristic and the applicable AS/NZS 3000 reference table before deciding pass or fail."
        }

        if protectionDeviceType == "MCB" {
            return "Protection is recorded as \(summary). Add the breaker curve when known so the loop helper can narrow the correct reference row."
        }

        return "Use the applicable AS/NZS 3000 reference table with the recorded protection details (\(summary)) to decide whether the measured Zs passes."
    }

    var guidanceText: String {
        if summary.isEmpty {
            return "Choose the protective device rating and family. The loop helper can narrow the correct reference row better when the breaker curve is known."
        }

        if requiresCurveForLoopGuidance && protectionCurve == "Not Set" {
            return "Add the breaker curve if known. Generic MCB/RCBO entries are not specific enough for the best loop guidance."
        }

        return "The PDF uses the combined result exactly as shown below."
    }

    var summary: String {
        let deviceText = protectionDeviceType == "Other" ? customDetails.normalizedFieldValue : protectionDeviceType

        return [
            selectedProtectionSize,
            deviceText,
            protectionCurve
        ]
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0 != "Not Set" }
        .joined(separator: " ")
    }

    static func parse(_ rawValue: String) -> ProtectionInputState {
        let trimmedValue = rawValue.normalizedFieldValue

        guard !trimmedValue.isEmpty else {
            return ProtectionInputState()
        }

        var state = ProtectionInputState()
        let lowercased = trimmedValue.lowercased()

        let tokens = trimmedValue
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        if let matchedSize = protectionSizes.first(where: { size in
            size != "Not Set" && tokens.contains(where: { token in
                token.caseInsensitiveCompare(size) == .orderedSame
            })
        }) {
            state.selectedProtectionSize = matchedSize
        }

        if lowercased.contains("fuse / rewirable fuse") || lowercased.contains("rewirable fuse") {
            state.protectionDeviceType = "Fuse / Rewirable Fuse"
        } else if lowercased.contains("hrc fuse") || lowercased.contains("hrc") {
            state.protectionDeviceType = "HRC Fuse"
        } else if lowercased.contains("main isolator") {
            state.protectionDeviceType = "Main Isolator"
        } else if lowercased.contains("rcbo") {
            state.protectionDeviceType = "RCBO"
        } else if lowercased.contains("mccb") {
            state.protectionDeviceType = "MCCB"
        } else if lowercased.contains("mcb") {
            state.protectionDeviceType = "MCB"
        }

        if lowercased.contains("type b") {
            state.protectionCurve = "Type B"
        } else if lowercased.contains("type c") {
            state.protectionCurve = "Type C"
        } else if lowercased.contains("type d") {
            state.protectionCurve = "Type D"
        }

        if state.protectionDeviceType == "Not Set", !trimmedValue.isEmpty,
           state.selectedProtectionSize == "Not Set" || tokens.count > 1 {
            state.protectionDeviceType = "Other"
            state.customDetails = trimmedValue
        }

        return state
    }
}

private struct StructuredRCDField: View {
    @Binding var value: String
    @Binding var tripTimeMs: String
    @Binding var protectionValue: String
    var errorMessage: String? = nil
    @State private var state = RCDInputState()

    private var isMainIsolator: Bool {
        ProtectionInputState.parse(protectionValue).protectionDeviceType == "Main Isolator"
    }

    var body: some View {
        Group {
        if !isMainIsolator {
        VStack(alignment: .leading, spacing: 10) {
            Text("RCD")
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            Menu {
                ForEach(RCDInputState.typeOptions, id: \.self) { option in
                    Button(option.isEmpty ? "Not Set" : option) {
                        updateType(option)
                    }
                }
            } label: {
                HStack {
                    Text(state.typeLabel)
                        .foregroundColor(state.type.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.npFieldSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(errorMessage == nil ? Color(uiColor: .separator) : .red, lineWidth: 1)
                )
                .cornerRadius(10)
            }

            if state.requiresStatus {
                PassFailField(
                    title: "RCD Result",
                    selection: $state.status,
                    helperText: "Record whether the RCD tripped correctly."
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text("Trip Time")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)

                    HStack(spacing: 10) {
                        TextField("Trip Time", text: $state.rcdTripTimeMs)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .autocorrectionDisabled()
                            .onChange(of: state.rcdTripTimeMs) { _, newValue in
                                let cleaned = cleanTripTimeInput(newValue)
                                if cleaned != newValue {
                                    state.rcdTripTimeMs = cleaned
                                    return
                                }

                                if tripTimeMs != cleaned {
                                    tripTimeMs = cleaned
                                }
                            }

                        Text("ms")
                            .font(.caption.bold())
                            .foregroundColor(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.npFieldSurface)
                            .cornerRadius(8)
                    }

                    Text("Optional. Include when you want the trip time shown.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if state.showsNotesField {
                EntryTextField(
                    title: state.type == "Other" ? "RCD Notes" : "Additional Notes",
                    placeholder: state.type == "Other" ? "Custom RCD details" : "Optional notes",
                    text: $state.notes
                )
            }

            if !state.summary.isEmpty {
                Text("Saved as: \(state.summary)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Use this field for RCD type, result, and optional trip time.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let outcome = state.assessment {
                AssessmentHelperCard(outcome: outcome, message: state.assessmentMessage)
            }

            if let errorMessage {
                InlineValidationText(message: errorMessage)
            }
        }
        } else {
            EmptyView()
        }
        }
        .onAppear {
            syncRCDState()
        }
        .onChange(of: state) { _, newState in
            let newValue = newState.summary
            if value != newValue {
                value = newValue
            }
            let newTripTime = cleanTripTimeInput(newState.rcdTripTimeMs)
            if tripTimeMs != newTripTime {
                tripTimeMs = newTripTime
            }
        }
        .onChange(of: value) { _, newValue in
            if isMainIsolator { return }
            guard newValue != state.summary else { return }
            let parsedState = RCDInputState.parse(newValue)
            if parsedState != state {
                var mergedState = parsedState
                let storedTripTime = cleanTripTimeInput(tripTimeMs)
                if cleanTripTimeInput(mergedState.rcdTripTimeMs).isEmpty {
                    mergedState.rcdTripTimeMs = storedTripTime
                } else {
                    mergedState.rcdTripTimeMs = cleanTripTimeInput(mergedState.rcdTripTimeMs)
                }
                state = mergedState
            }
        }
        .onChange(of: tripTimeMs) { _, newValue in
            let cleanedValue = cleanTripTimeInput(newValue)
            if state.rcdTripTimeMs != cleanedValue {
                state.rcdTripTimeMs = cleanedValue
            }
        }
        .onChange(of: protectionValue) { _, _ in
            syncRCDState()
        }
    }

    private func updateType(_ newType: String) {
        state.type = newType

        if newType.isEmpty || newType == "N/A" {
            state.status = ""
            state.rcdTripTimeMs = ""
        }
    }

    private func syncRCDState() {
        if isMainIsolator {
            value = "N/A"
            tripTimeMs = ""
            state = RCDInputState(type: "N/A", status: "", rcdTripTimeMs: "", notes: "")
            return
        }

        state = RCDInputState.parse(value)
        let storedTripTime = cleanTripTimeInput(tripTimeMs)
        let parsedTripTime = cleanTripTimeInput(state.rcdTripTimeMs)
        let exactTripTime = storedTripTime.isEmpty ? parsedTripTime : storedTripTime
        state.rcdTripTimeMs = exactTripTime
    }
}

struct NumericKeyboardDoneToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                } label: {
                    Text("Done")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(minWidth: 90, minHeight: 44)
                        .padding(.horizontal, 12)
                        .background(Color.npBrandYellow)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

extension View {
    func numericKeyboardDoneToolbar() -> some View {
        modifier(NumericKeyboardDoneToolbar())
    }
}

private struct RCDInputState: Equatable {
    static let typeOptions = ["", "N/A", "30mA", "100mA", "RCBO", "Other"]

    var type = ""
    var status = ""
    var rcdTripTimeMs = ""
    var notes = ""

    var typeLabel: String {
        type.isEmpty ? "Select RCD setup" : type
    }

    var requiresStatus: Bool {
        !type.isEmpty && type != "N/A"
    }

    var showsNotesField: Bool {
        !type.isEmpty
    }

    var assessment: SuggestedAssessment? {
        guard !type.isEmpty else { return nil }

        if type == "N/A" {
            return .notApplicable
        }

        if status == "Fail" {
            return .fail
        }

        if status == "Pass" {
            return .pass
        }

        return .needsReference
    }

    var assessmentMessage: String {
        switch assessment {
        case .notApplicable:
            return "No RCD assessment is needed for this circuit entry."
        case .fail:
            return "The recorded RCD result is fail. Investigate the device, test setup, and applicable AS/NZS 3000 Section 8.3.10 requirements."
        case .pass:
            if rcdTripTimeMs.normalizedFieldValue.isEmpty {
                return "The RCD is recorded as a pass. Add a trip time when available and confirm the test current and timing requirements against AS/NZS 3000 Section 8.3.10."
            }
            return "The RCD is recorded as a pass. Confirm the trip time and applied test current against AS/NZS 3000 Section 8.3.10 and the installed device."
        case .needsReference:
            return "Select the RCD result and confirm the device/test conditions before deciding pass or fail."
        case nil:
            return ""
        }
    }

    var summary: String {
        let trimmedNotes = notes.normalizedFieldValue
        let trimmedTripTime = rcdTripTimeMs.normalizedFieldValue

        guard !type.isEmpty else {
            return ""
        }

        if type == "N/A" {
            return trimmedNotes.isEmpty ? "N/A" : "N/A \(trimmedNotes)"
        }

        var components = [String]()

        if type == "Other" {
            if !trimmedNotes.isEmpty {
                components.append(trimmedNotes)
            } else {
                components.append("Other")
            }
        } else {
            components.append(type)
            if !status.isEmpty {
                components.append(status)
            }
            if !trimmedTripTime.isEmpty {
                components.append("\(trimmedTripTime)ms")
            }
            if !trimmedNotes.isEmpty {
                components.append(trimmedNotes)
            }
        }

        return components.joined(separator: " ")
    }

    static func parse(_ rawValue: String) -> RCDInputState {
        let trimmedValue = rawValue.normalizedFieldValue

        guard !trimmedValue.isEmpty else {
            return RCDInputState()
        }

        var state = RCDInputState()
        let lowercased = trimmedValue.lowercased()

        if lowercased == "n/a" || lowercased.contains("not applicable") {
            state.type = "N/A"
        } else if lowercased.contains("rcbo") {
            state.type = "RCBO"
        } else if lowercased.contains("100ma") || lowercased.contains("100 ma") {
            state.type = "100mA"
        } else if lowercased.contains("30ma") || lowercased.contains("30 ma") {
            state.type = "30mA"
        } else {
            state.type = "Other"
        }

        if lowercased.contains("pass") {
            state.status = "Pass"
        } else if lowercased.contains("fail") {
            state.status = "Fail"
        }

        if let match = trimmedValue.range(of: #"\d+(?:\.\d+)?\s*ms"#, options: .regularExpression) {
            let tripValue = String(trimmedValue[match])
            state.rcdTripTimeMs = tripValue
                .replacingOccurrences(of: "ms", with: "", options: .caseInsensitive)
                .normalizedFieldValue
        }

        var notes = trimmedValue
        let replacements = ["30mA", "30 mA", "100mA", "100 mA", "RCBO", "Pass", "Fail", "N/A", "n/a"]
        for token in replacements {
            notes = notes.replacingOccurrences(of: token, with: "", options: .caseInsensitive)
        }
        notes = notes.replacingOccurrences(of: #"\d+(?:\.\d+)?\s*ms"#, with: "", options: .regularExpression)
        notes = notes.normalizedFieldValue

        if state.type == "Other" {
            state.notes = trimmedValue
        } else {
            state.notes = notes
        }

        return state
    }
}

private extension String {
    var normalizedFieldValue: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    var numericDoubleValue: Double? {
        let normalized = normalizedFieldValue
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "MΩ", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Ω", with: "", options: .caseInsensitive)
            .normalizedFieldValue

        return Double(normalized)
    }

    var sanitizedIdentifier: String {
        uppercased()
            .filter { character in
                character.isLetter || character.isNumber || character == " " || character == "-" || character == "/"
            }
            .normalizedFieldValue
    }
}

private func cleanTripTimeInput(_ value: String) -> String {
    var output = ""
    var hasDecimal = false

    for char in value {
        if char.isNumber {
            output.append(char)
        } else if char == "." && !hasDecimal {
            hasDecimal = true
            output.append(char)
        }
    }

    return output
}

struct TestResultEditView: View {
    @Binding var result: TestResult
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            Form {
                Section("Circuit Details") {
                    DatePicker(
                        "Test Date",
                        selection: Binding(
                            get: {
                                TestResultsTableView.testDateFormatter.date(from: result.testDate) ?? Date()
                            },
                            set: { newDate in
                                result.testDate = TestResultsTableView.testDateFormatter.string(from: newDate)
                            }
                        ),
                        displayedComponents: .date
                    )

                    EntryTextField(
                        title: "Circuit / Equipment",
                        placeholder: "Lighting, GPO, A/C, Pump",
                        text: $result.circuitOrEquipment
                    )
                    IdentifierField(
                        title: "Circuit No.",
                        placeholder: "C1",
                        text: $result.circuitNo,
                        helperText: "Uppercase letters, numbers, spaces, dash and slash only."
                    )
                    IdentifierField(
                        title: "Neutral No.",
                        placeholder: "N1",
                        text: $result.neutralNo,
                        helperText: "Uppercase letters, numbers, spaces, dash and slash only."
                    )
                }

                Section("Checks") {
                    VisualInspectionHelperField(value: $result.visualInspection)
                    PolarityHelperField(value: $result.polarityTest)
                    PassFailField(title: "Operational Test", selection: $result.operationalTest)
                }

                Section("Measurements") {
                    StructuredCableSizeField(value: $result.cableSize)
                    StructuredProtectionField(value: $result.protectionSizeType)
                    EarthContinuityHelperField(value: $result.earthContinuity)
                    StructuredRCDField(value: $result.rcd, tripTimeMs: $result.rcdTripTimeMs, protectionValue: $result.protectionSizeType)
                    InsulationResistanceHelperField(
                        selectedPhases: $result.selectedPhases,
                        mohmsValue: $result.insulationResistanceMohms,
                        legacyValue: $result.insulationResistance,
                        testVoltage: $result.irTestVoltage
                    )
                    FaultLoopImpedanceHelperField(
                        value: $result.faultLoopImpedance,
                        protectionValue: $result.protectionSizeType,
                        testMethodValue: $result.testMethod,
                        systemVoltageValue: $result.systemVoltage,
                        disconnectionTimeValue: $result.disconnectionTime,
                        activeConductorSizeValue: $result.cableSize,
                        earthConductorSizeValue: $result.earthConductorSize,
                        mainIsolatorSupplyTypeValue: $result.mainIsolatorSupplyType,
                        mainIsolatorActiveZsValue: $result.mainIsolatorActiveZs,
                        mainIsolatorPhaseAZsValue: $result.mainIsolatorPhaseAZs,
                        mainIsolatorPhaseBZsValue: $result.mainIsolatorPhaseBZs,
                        mainIsolatorPhaseCZsValue: $result.mainIsolatorPhaseCZs
                    )
                }
            }
            .numericKeyboardDoneToolbar()
            .navigationTitle("Edit Circuit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
}
