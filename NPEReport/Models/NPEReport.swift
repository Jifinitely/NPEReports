import Foundation

enum ReportLifecycleStatus: String, Codable, CaseIterable, Identifiable {
    case inProgress
    case complete
    case sent

    var id: String { rawValue }

    var label: String {
        switch self {
        case .inProgress:
            return "In Progress"
        case .complete:
            return "Complete"
        case .sent:
            return "Sent"
        }
    }
}

enum TemplateScope: String, Codable, CaseIterable, Identifiable {
    case board
    case circuitsOnly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .board:
            return "Board Template"
        case .circuitsOnly:
            return "Circuit Set"
        }
    }

    var applyButtonTitle: String {
        switch self {
        case .board:
            return "Use Board Template"
        case .circuitsOnly:
            return "Apply Circuits"
        }
    }
}

struct NPEReport: Identifiable, Codable, Equatable {
    let id: UUID
    var reportTitle: String
    var customer: String
    var siteAddress: String
    var switchboardLocation: String
    var buildingNumber: String
    var jobNumber: String
    var chassisID: String
    var testResults: [TestResult]
    var attachments: [ReportAttachment]
    var testedBy: String
    var licenceNumber: String
    var testerModel: String
    var testerSerialNumber: String
    var date: Date
    var lifecycleStatus: ReportLifecycleStatus
    var isArchived: Bool
    var signatureData: Data?

    enum CodingKeys: String, CodingKey {
        case id
        case reportTitle
        case customer
        case siteAddress
        case switchboardLocation
        case buildingNumber
        case jobNumber
        case chassisID
        case testResults
        case attachments
        case testedBy
        case licenceNumber
        case testerModel
        case testerSerialNumber
        case date
        case lifecycleStatus
        case isArchived
        case signatureData
        case jobNo
    }

    init(
        id: UUID = UUID(),
        reportTitle: String = "",
        customer: String,
        siteAddress: String,
        switchboardLocation: String,
        buildingNumber: String,
        jobNumber: String,
        chassisID: String,
        testResults: [TestResult],
        attachments: [ReportAttachment] = [],
        testedBy: String,
        licenceNumber: String,
        testerModel: String = "",
        testerSerialNumber: String = "",
        date: Date,
        lifecycleStatus: ReportLifecycleStatus = .inProgress,
        isArchived: Bool = false,
        signatureData: Data?
    ) {
        self.id = id
        self.reportTitle = reportTitle
        self.customer = customer
        self.siteAddress = siteAddress
        self.switchboardLocation = switchboardLocation
        self.buildingNumber = buildingNumber
        self.jobNumber = jobNumber
        self.chassisID = chassisID
        self.testResults = testResults
        self.attachments = attachments
        self.testedBy = testedBy
        self.licenceNumber = licenceNumber
        self.testerModel = testerModel
        self.testerSerialNumber = testerSerialNumber
        self.date = date
        self.lifecycleStatus = lifecycleStatus
        self.isArchived = isArchived
        self.signatureData = signatureData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        reportTitle = try container.decodeIfPresent(String.self, forKey: .reportTitle) ?? ""
        customer = try container.decodeIfPresent(String.self, forKey: .customer) ?? ""
        siteAddress = try container.decodeIfPresent(String.self, forKey: .siteAddress) ?? ""
        switchboardLocation = try container.decodeIfPresent(String.self, forKey: .switchboardLocation) ?? ""
        buildingNumber = try container.decodeIfPresent(String.self, forKey: .buildingNumber) ?? ""
        jobNumber = try container.decodeIfPresent(String.self, forKey: .jobNumber)
            ?? container.decodeIfPresent(String.self, forKey: .jobNo)
            ?? ""
        chassisID = try container.decodeIfPresent(String.self, forKey: .chassisID) ?? ""
        testResults = try container.decodeIfPresent([TestResult].self, forKey: .testResults) ?? []
        attachments = try container.decodeIfPresent([ReportAttachment].self, forKey: .attachments) ?? []
        testedBy = try container.decodeIfPresent(String.self, forKey: .testedBy) ?? ""
        licenceNumber = try container.decodeIfPresent(String.self, forKey: .licenceNumber) ?? ""
        testerModel = try container.decodeIfPresent(String.self, forKey: .testerModel) ?? ""
        testerSerialNumber = try container.decodeIfPresent(String.self, forKey: .testerSerialNumber) ?? ""
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        lifecycleStatus = try container.decodeIfPresent(ReportLifecycleStatus.self, forKey: .lifecycleStatus) ?? .complete
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        signatureData = try container.decodeIfPresent(Data.self, forKey: .signatureData)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(reportTitle, forKey: .reportTitle)
        try container.encode(customer, forKey: .customer)
        try container.encode(siteAddress, forKey: .siteAddress)
        try container.encode(switchboardLocation, forKey: .switchboardLocation)
        try container.encode(buildingNumber, forKey: .buildingNumber)
        try container.encode(jobNumber, forKey: .jobNumber)
        try container.encode(jobNumber, forKey: .jobNo)
        try container.encode(chassisID, forKey: .chassisID)
        try container.encode(testResults, forKey: .testResults)
        try container.encode(attachments, forKey: .attachments)
        try container.encode(testedBy, forKey: .testedBy)
        try container.encode(licenceNumber, forKey: .licenceNumber)
        try container.encode(testerModel, forKey: .testerModel)
        try container.encode(testerSerialNumber, forKey: .testerSerialNumber)
        try container.encode(date, forKey: .date)
        try container.encode(lifecycleStatus, forKey: .lifecycleStatus)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encodeIfPresent(signatureData, forKey: .signatureData)
    }
}

extension NPEReport {
    var displayTitle: String {
        if !reportTitle.normalizedFieldValue.isEmpty {
            return reportTitle.normalizedFieldValue
        }

        if !customer.normalizedFieldValue.isEmpty {
            return customer.normalizedFieldValue
        }

        if !switchboardLocation.normalizedFieldValue.isEmpty {
            return switchboardLocation.normalizedFieldValue
        }

        return "Untitled Report"
    }

    var lifecycleSummary: String {
        isArchived ? "\(lifecycleStatus.label) • Archived" : lifecycleStatus.label
    }

    var reportNumber: String {
        String(id.uuidString.prefix(8)).uppercased()
    }

    var exportFileName: String {
        let parts = [
            "NPEReport",
            sanitizedFilePart(reportTitle),
            sanitizedFilePart(customer),
            sanitizedFilePart(jobNumber),
            Self.fileDateFormatter.string(from: date)
        ]

        return parts
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }

    func duplicatedForTemplate() -> NPEReport {
        NPEReport(
            id: UUID(),
            reportTitle: "",
            customer: customer,
            siteAddress: siteAddress,
            switchboardLocation: switchboardLocation,
            buildingNumber: buildingNumber,
            jobNumber: jobNumber,
            chassisID: chassisID,
            testResults: testResults.map { $0.duplicated() },
            attachments: attachments.map { $0.duplicated() },
            testedBy: testedBy,
            licenceNumber: licenceNumber,
            testerModel: testerModel,
            testerSerialNumber: testerSerialNumber,
            date: Date(),
            lifecycleStatus: .inProgress,
            isArchived: false,
            signatureData: signatureData
        )
    }

    func templateSnapshot(for scope: TemplateScope) -> NPEReport {
        let keepsBoardDetails = scope == .board

        return NPEReport(
            id: UUID(),
            reportTitle: "",
            customer: keepsBoardDetails ? customer : "",
            siteAddress: keepsBoardDetails ? siteAddress : "",
            switchboardLocation: keepsBoardDetails ? switchboardLocation : "",
            buildingNumber: keepsBoardDetails ? buildingNumber : "",
            jobNumber: keepsBoardDetails ? jobNumber : "",
            chassisID: keepsBoardDetails ? chassisID : "",
            testResults: testResults.map { $0.duplicated() },
            attachments: [],
            testedBy: "",
            licenceNumber: "",
            testerModel: "",
            testerSerialNumber: "",
            date: Date(),
            lifecycleStatus: .inProgress,
            isArchived: false,
            signatureData: nil
        )
    }

    func suggestedTemplateName(for scope: TemplateScope) -> String {
        let baseName = [
            switchboardLocation.normalizedFieldValue,
            customer.normalizedFieldValue,
            buildingNumber.normalizedFieldValue
        ]
        .first(where: { !$0.isEmpty }) ?? "Untitled"

        switch scope {
        case .board:
            return "\(baseName) Board Template"
        case .circuitsOnly:
            return "\(baseName) Circuit Set"
        }
    }

    private func sanitizedFilePart(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "[^A-Za-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct SavedReportTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var scope: TemplateScope
    var reportSnapshot: NPEReport
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        scope: TemplateScope,
        reportSnapshot: NPEReport,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.scope = scope
        self.reportSnapshot = reportSnapshot
        self.createdAt = createdAt
    }

    var circuitCount: Int {
        reportSnapshot.testResults.count
    }

    var displayName: String {
        name.normalizedFieldValue.isEmpty ? reportSnapshot.suggestedTemplateName(for: scope) : name.normalizedFieldValue
    }
}

struct ReportAttachment: Identifiable, Codable, Hashable {
    enum CodingKeys: String, CodingKey {
        case id
        case fileName
        case imageData
        case createdAt
        case imageFileName
    }

    let id: UUID
    var fileName: String
    var imageData: Data?
    var createdAt: Date
    var imageFileName: String?

    init(
        id: UUID = UUID(),
        fileName: String,
        imageData: Data? = nil,
        createdAt: Date = Date(),
        imageFileName: String? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.imageData = imageData
        self.createdAt = createdAt
        self.imageFileName = imageFileName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        fileName = try container.decodeIfPresent(String.self, forKey: .fileName) ?? ""
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        imageFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fileName, forKey: .fileName)
        try container.encodeIfPresent(imageData, forKey: .imageData)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(imageFileName, forKey: .imageFileName)
    }

    func duplicated() -> ReportAttachment {
        ReportAttachment(
            fileName: fileName,
            imageData: imageData,
            createdAt: createdAt,
            imageFileName: imageFileName
        )
    }
}

struct TestResult: Identifiable, Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case id
        case testDate
        case circuitOrEquipment
        case visualInspection
        case circuitNo
        case cableSize
        case protectionSizeType
        case neutralNo
        case earthContinuity
        case rcd
        case rcdTripTimeMs
        case insulationResistance
        case insulationResistanceMohms
        case selectedPhases
        case irTestVoltage
        case polarityTest
        case faultLoopImpedance
        case operationalTest
        case testMethod
        case systemVoltage
        case disconnectionTime
        case earthConductorSize
        case mainIsolatorSupplyType
        case mainIsolatorActiveZs
        case mainIsolatorPhaseAZs
        case mainIsolatorPhaseBZs
        case mainIsolatorPhaseCZs
    }

    static let defaultTestMethod = "Zs"
    static let defaultSystemVoltage = "230V"
    static let defaultDisconnectionTime = "0.4s"
    static let defaultIRTestVoltage = "500V"

    let id: UUID
    var testDate: String
    var circuitOrEquipment: String
    var visualInspection: String
    var circuitNo: String
    var cableSize: String
    var protectionSizeType: String
    var neutralNo: String
    var earthContinuity: String
    var rcd: String
    var rcdTripTimeMs: String
    var insulationResistance: String
    var insulationResistanceMohms: String
    var selectedPhases: [String]
    var irTestVoltage: String
    var polarityTest: String
    var faultLoopImpedance: String
    var operationalTest: String
    var testMethod: String
    var systemVoltage: String
    var disconnectionTime: String
    var earthConductorSize: String
    var mainIsolatorSupplyType: String
    var mainIsolatorActiveZs: String
    var mainIsolatorPhaseAZs: String
    var mainIsolatorPhaseBZs: String
    var mainIsolatorPhaseCZs: String

    init(
        id: UUID,
        testDate: String,
        circuitOrEquipment: String,
        visualInspection: String,
        circuitNo: String,
        cableSize: String,
        protectionSizeType: String,
        neutralNo: String,
        earthContinuity: String,
        rcd: String,
        rcdTripTimeMs: String = "",
        insulationResistance: String,
        insulationResistanceMohms: String = "",
        selectedPhases: [String] = [],
        irTestVoltage: String = Self.defaultIRTestVoltage,
        polarityTest: String,
        faultLoopImpedance: String,
        operationalTest: String,
        testMethod: String = Self.defaultTestMethod,
        systemVoltage: String = Self.defaultSystemVoltage,
        disconnectionTime: String = Self.defaultDisconnectionTime,
        earthConductorSize: String = "",
        mainIsolatorSupplyType: String = "",
        mainIsolatorActiveZs: String = "",
        mainIsolatorPhaseAZs: String = "",
        mainIsolatorPhaseBZs: String = "",
        mainIsolatorPhaseCZs: String = ""
    ) {
        self.id = id
        self.testDate = testDate
        self.circuitOrEquipment = circuitOrEquipment
        self.visualInspection = visualInspection
        self.circuitNo = circuitNo
        self.cableSize = cableSize
        self.protectionSizeType = protectionSizeType
        self.neutralNo = neutralNo
        self.earthContinuity = earthContinuity
        self.rcd = rcd
        self.rcdTripTimeMs = rcdTripTimeMs
        self.insulationResistance = insulationResistance
        self.insulationResistanceMohms = insulationResistanceMohms
        self.selectedPhases = selectedPhases
        self.irTestVoltage = irTestVoltage
        self.polarityTest = polarityTest
        self.faultLoopImpedance = faultLoopImpedance
        self.operationalTest = operationalTest
        self.testMethod = testMethod
        self.systemVoltage = systemVoltage
        self.disconnectionTime = disconnectionTime
        self.earthConductorSize = earthConductorSize
        self.mainIsolatorSupplyType = mainIsolatorSupplyType
        self.mainIsolatorActiveZs = mainIsolatorActiveZs
        self.mainIsolatorPhaseAZs = mainIsolatorPhaseAZs
        self.mainIsolatorPhaseBZs = mainIsolatorPhaseBZs
        self.mainIsolatorPhaseCZs = mainIsolatorPhaseCZs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        testDate = try container.decode(String.self, forKey: .testDate)
        circuitOrEquipment = try container.decode(String.self, forKey: .circuitOrEquipment)
        visualInspection = try container.decode(String.self, forKey: .visualInspection)
        circuitNo = try container.decode(String.self, forKey: .circuitNo)
        cableSize = try container.decode(String.self, forKey: .cableSize)
        protectionSizeType = try container.decode(String.self, forKey: .protectionSizeType)
        neutralNo = try container.decode(String.self, forKey: .neutralNo)
        earthContinuity = try container.decode(String.self, forKey: .earthContinuity)
        rcd = try container.decode(String.self, forKey: .rcd)
        rcdTripTimeMs = try container.decodeIfPresent(String.self, forKey: .rcdTripTimeMs) ?? ""
        insulationResistance = try container.decode(String.self, forKey: .insulationResistance)
        insulationResistanceMohms = try container.decodeIfPresent(String.self, forKey: .insulationResistanceMohms) ?? insulationResistance
        selectedPhases = try container.decodeIfPresent([String].self, forKey: .selectedPhases) ?? []
        irTestVoltage = try container.decodeIfPresent(String.self, forKey: .irTestVoltage) ?? Self.defaultIRTestVoltage
        polarityTest = try container.decode(String.self, forKey: .polarityTest)
        faultLoopImpedance = try container.decode(String.self, forKey: .faultLoopImpedance)
        operationalTest = try container.decode(String.self, forKey: .operationalTest)
        testMethod = try container.decodeIfPresent(String.self, forKey: .testMethod) ?? Self.defaultTestMethod
        systemVoltage = try container.decodeIfPresent(String.self, forKey: .systemVoltage) ?? Self.defaultSystemVoltage
        disconnectionTime = try container.decodeIfPresent(String.self, forKey: .disconnectionTime) ?? Self.defaultDisconnectionTime
        earthConductorSize = try container.decodeIfPresent(String.self, forKey: .earthConductorSize) ?? ""
        mainIsolatorSupplyType = try container.decodeIfPresent(String.self, forKey: .mainIsolatorSupplyType) ?? ""
        mainIsolatorActiveZs = try container.decodeIfPresent(String.self, forKey: .mainIsolatorActiveZs) ?? ""
        mainIsolatorPhaseAZs = try container.decodeIfPresent(String.self, forKey: .mainIsolatorPhaseAZs) ?? ""
        mainIsolatorPhaseBZs = try container.decodeIfPresent(String.self, forKey: .mainIsolatorPhaseBZs) ?? ""
        mainIsolatorPhaseCZs = try container.decodeIfPresent(String.self, forKey: .mainIsolatorPhaseCZs) ?? ""
    }
}

extension TestResult {
    static func blank() -> TestResult {
        TestResult(
            id: UUID(),
            testDate: "",
            circuitOrEquipment: "",
            visualInspection: "",
            circuitNo: "",
            cableSize: "",
            protectionSizeType: "",
            neutralNo: "",
            earthContinuity: "",
            rcd: "",
            rcdTripTimeMs: "",
            insulationResistance: "",
            insulationResistanceMohms: "",
            selectedPhases: [],
            irTestVoltage: TestResult.defaultIRTestVoltage,
            polarityTest: "",
            faultLoopImpedance: "",
            operationalTest: "",
            testMethod: TestResult.defaultTestMethod,
            systemVoltage: TestResult.defaultSystemVoltage,
            disconnectionTime: TestResult.defaultDisconnectionTime,
            earthConductorSize: "",
            mainIsolatorSupplyType: "",
            mainIsolatorActiveZs: "",
            mainIsolatorPhaseAZs: "",
            mainIsolatorPhaseBZs: "",
            mainIsolatorPhaseCZs: ""
        )
    }

    func duplicated() -> TestResult {
        TestResult(
            id: UUID(),
            testDate: testDate,
            circuitOrEquipment: circuitOrEquipment,
            visualInspection: visualInspection,
            circuitNo: circuitNo,
            cableSize: cableSize,
            protectionSizeType: protectionSizeType,
            neutralNo: neutralNo,
            earthContinuity: earthContinuity,
            rcd: rcd,
            rcdTripTimeMs: rcdTripTimeMs,
            insulationResistance: insulationResistance,
            insulationResistanceMohms: insulationResistanceMohms,
            selectedPhases: selectedPhases,
            irTestVoltage: irTestVoltage,
            polarityTest: polarityTest,
            faultLoopImpedance: faultLoopImpedance,
            operationalTest: operationalTest,
            testMethod: testMethod,
            systemVoltage: systemVoltage,
            disconnectionTime: disconnectionTime,
            earthConductorSize: earthConductorSize,
            mainIsolatorSupplyType: mainIsolatorSupplyType,
            mainIsolatorActiveZs: mainIsolatorActiveZs,
            mainIsolatorPhaseAZs: mainIsolatorPhaseAZs,
            mainIsolatorPhaseBZs: mainIsolatorPhaseBZs,
            mainIsolatorPhaseCZs: mainIsolatorPhaseCZs
        )
    }

    var missingRequiredFields: [String] {
        var missingFields = [String]()

        if Self.isBlank(testDate) { missingFields.append("Test Date") }
        if Self.isBlank(circuitOrEquipment) { missingFields.append("Circuit / Equipment") }
        if Self.isBlank(visualInspection) { missingFields.append("Visual Inspection") }
        if Self.isBlank(circuitNo) { missingFields.append("Circuit No.") }
        if Self.isBlank(cableSize) { missingFields.append("Cable Size") }
        if Self.isBlank(protectionSizeType) { missingFields.append("Protection") }
        if Self.isBlank(neutralNo) { missingFields.append("Neutral No.") }
        if Self.isBlank(earthContinuity) { missingFields.append("Earth Continuity") }
        if !isMainIsolator, Self.isBlank(rcd) { missingFields.append("RCD") }
        if selectedPhases.isEmpty { missingFields.append("Phase") }
        if Self.isBlank(irResultValue) { missingFields.append("IR Result (MΩ)") }
        if Self.isBlank(polarityTest) { missingFields.append("Polarity Test") }
        if !isMainIsolator, Self.isBlank(faultLoopImpedance) { missingFields.append("Fault Loop Impedance") }
        if !isMainIsolator, testMethod == "R1+R2", Self.isBlank(earthConductorSize) { missingFields.append("Earth Conductor Size") }
        if Self.isBlank(operationalTest) { missingFields.append("Operational Test") }

        return missingFields
    }

    var isComplete: Bool {
        missingRequiredFields.isEmpty
    }

    var irResultValue: String {
        let newValue = insulationResistanceMohms.trimmingCharacters(in: .whitespacesAndNewlines)
        if !newValue.isEmpty {
            return newValue
        }
        return insulationResistance.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var formattedSelectedPhases: String {
        let orderedPhases = ["A", "B", "C"].filter { selectedPhases.contains($0) }
        return orderedPhases.joined(separator: "+")
    }

    var isMainIsolator: Bool {
        protectionSizeType.localizedCaseInsensitiveContains("main isolator")
    }

    var displayRCDValue: String {
        isMainIsolator ? "N/A" : rcd
    }

    var mainIsolatorFaultLoopLines: [String] {
        guard isMainIsolator else { return [] }

        if mainIsolatorSupplyType == "Three Phase" {
            return [
                ("A", mainIsolatorPhaseAZs),
                ("B", mainIsolatorPhaseBZs),
                ("C", mainIsolatorPhaseCZs)
            ]
            .compactMap { phase, value in
                let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedValue.isEmpty else { return nil }
                return "\(phase): \(trimmedValue)Ω"
            }
        }

        let trimmedValue = mainIsolatorActiveZs.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return [] }
        return ["Active: \(trimmedValue)Ω"]
    }

    var mainIsolatorFaultLoopSummary: String {
        guard isMainIsolator else { return faultLoopImpedance }

        var lines = mainIsolatorFaultLoopLines
        lines.append("Record only")
        lines.append("Upstream protection to verify")
        return lines.joined(separator: "\n")
    }

    private static func isBlank(_ value: String) -> Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private extension String {
    var normalizedFieldValue: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
