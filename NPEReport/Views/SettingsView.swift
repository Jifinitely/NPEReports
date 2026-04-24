import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("companyName") private var companyName = "N & P Contracting"
    @AppStorage("companyAddress") private var companyAddress = "Unit 9 / 48 Tennyson Memorial Avenue, Tennyson QLD 4105"
    @AppStorage("companyPhone") private var companyPhone = "07 3892 3399"
    @AppStorage("companyEmail") private var companyEmail = "info@npcontracting.com.au"
    @AppStorage("companyABN") private var companyABN = "51 709 046 128"
    @AppStorage("companyLicense") private var companyLicense = "65051"
    @AppStorage("testerName") private var testerName = ""
    @AppStorage("testerLicense") private var testerLicense = ""
    @AppStorage("testerModel") private var testerModel = ""
    @AppStorage("testerSerialNumber") private var testerSerialNumber = ""
    @AppStorage("defaultSignature") private var defaultSignature: Data?
    @State private var showSignatureEditor = false
    @State private var showReplaceDefaultSignatureAlert = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showExportSheet = false
    @State private var exportData: Data?
    @State private var showImportPicker = false
    @State private var showResetAlert = false
    @State private var showHelp = false

    private var defaultSignatureImage: UIImage? {
        guard let defaultSignature else { return nil }
        return UIImage(data: defaultSignature)
    }

    private var defaultSignatureActions: [SignatureAction] {
        var actions = [
            SignatureAction(
                title: defaultSignatureImage == nil ? "Set Default Signature" : "Replace Default Signature",
                style: .primary,
                action: beginDefaultSignatureCapture
            )
        ]

        if defaultSignatureImage != nil {
            actions.append(
                SignatureAction(
                    title: "Clear Default Signature",
                    style: .destructive,
                    action: clearDefaultSignature
                )
            )
        }

        return actions
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                BrandHeaderView(title: "Settings")

                Form {
                    Section(
                        header: Text("Company Information")
                            .foregroundColor(.npBrandYellow)
                            .fontWeight(.bold)
                    ) {
                        TextField("Company Name", text: $companyName)
                        TextField("Address", text: $companyAddress)
                        TextField("Phone", text: $companyPhone)
                        TextField("Email", text: $companyEmail)
                        TextField("ABN", text: $companyABN)
                        TextField("License Number", text: $companyLicense)
                    }

                    Section(
                        header: Text("Default Tester Information")
                            .foregroundColor(.npBrandYellow)
                            .fontWeight(.bold)
                    ) {
                        TextField("Tester Name", text: $testerName)
                        TextField("License Number", text: $testerLicense)
                        TextField("Tester Model", text: $testerModel)
                        TextField("Tester Serial Number", text: $testerSerialNumber)
                    }

                    Section(
                        header: Text("Signature Management")
                            .foregroundColor(.npBrandYellow)
                            .fontWeight(.bold)
                    ) {
                        SignaturePreviewPanel(
                            title: "Default Signature",
                            signatureImage: defaultSignatureImage,
                            statusText: defaultSignatureImage == nil ? "No default signature saved." : "This signature is applied automatically to new reports.",
                            helperText: "Use the full-screen editor to save a clean default signature with Save, Clear, and Cancel controls.",
                            actions: defaultSignatureActions
                        )
                    }

                    Section(
                        header: Text("Appearance")
                            .foregroundColor(.npBrandYellow)
                            .fontWeight(.bold)
                    ) {
                        Toggle("Dark Mode", isOn: $isDarkMode)
                    }

                    Section(
                        header: Text("Export/Backup")
                            .foregroundColor(.npBrandYellow)
                            .fontWeight(.bold)
                    ) {
                        Button("Export All Reports") {
                            let payload = AppBackupPayload(
                                reports: HistoryStorage.load(),
                                templates: TemplateStorage.load()
                            )
                            if let data = try? JSONEncoder().encode(payload) {
                                exportData = data
                                showExportSheet = true
                            }
                        }
                        .padding(6)
                        .background(Color.npBrandYellow)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                        .sheet(isPresented: $showExportSheet) {
                            if let exportData {
                                ActivityView(activityItems: [exportData])
                            }
                        }

                        Button("Import/Restore Backup") {
                            showImportPicker = true
                        }
                        .padding(6)
                        .background(Color.npBrandYellow)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                        .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
                            switch result {
                            case .success(let url):
                                let isSecurityScoped = url.startAccessingSecurityScopedResource()
                                defer {
                                    if isSecurityScoped {
                                        url.stopAccessingSecurityScopedResource()
                                    }
                                }

                                if let data = try? Data(contentsOf: url),
                                   let payload = AppBackupPayload.decode(from: data) {
                                    HistoryStorage.save(payload.reports)
                                    TemplateStorage.save(payload.templates)
                                }
                            case .failure:
                                break
                            }
                        }
                    }

                    Section(
                        header: Text("Reset App Data")
                            .foregroundColor(.npBrandYellow)
                            .fontWeight(.bold)
                    ) {
                        Button("Reset All Data") {
                            showResetAlert = true
                        }
                        .foregroundColor(.red)
                    }

                    Section(
                        header: Text("About/Help")
                            .foregroundColor(.npBrandYellow)
                            .fontWeight(.bold)
                    ) {
                        Text("Version 4.0")
                        Text("Support: info@npcontracting.com.au")
                            .foregroundColor(.black)
                        NavigationLink("Testing Help & Standards", destination: StandardsView())
                        Button("App Help & Instructions") { showHelp = true }
                    }
                }
                .numericKeyboardDoneToolbar()
                .alert(isPresented: $showResetAlert) {
                    Alert(
                        title: Text("Reset All Data?"),
                        message: Text("This will delete all saved reports and settings. This action cannot be undone."),
                        primaryButton: .destructive(Text("Reset")) {
                            if let bundleIdentifier = Bundle.main.bundleIdentifier {
                                UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
                .fullScreenCover(isPresented: $showSignatureEditor) {
                    SignatureEditorView(
                        title: "Default Signature",
                        replacementNotice: defaultSignatureImage == nil ? nil : "Saving here will replace the default signature used on new reports."
                    ) { image in
                        defaultSignature = image.pngData()
                    }
                }
                .sheet(isPresented: $showHelp) {
                    HelpView()
                }
                .alert("Replace Default Signature?", isPresented: $showReplaceDefaultSignatureAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Replace", role: .destructive) {
                        showSignatureEditor = true
                    }
                } message: {
                    Text("This will replace the default signature used for new reports.")
                }
            }
        }
    }

    private func beginDefaultSignatureCapture() {
        if defaultSignatureImage != nil {
            showReplaceDefaultSignatureAlert = true
        } else {
            showSignatureEditor = true
        }
    }

    private func clearDefaultSignature() {
        defaultSignature = nil
    }
}

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AppHelpCard(
                        title: "Creating a Report",
                        rows: [
                            "Fill in customer, site address, job number, switchboard location, and tester details.",
                            "Complete required fields before generating the PDF.",
                            "Company, tester, and signature defaults can be managed from Settings."
                        ]
                    )

                    AppHelpCard(
                        title: "Adding Circuit Results",
                        rows: [
                            "Enter each circuit or tested item as a separate result.",
                            "Use the protection fields to record breaker, RCBO, RCD, fuse, MCCB, or main isolator details.",
                            "Use Duplicate when several circuits have similar details.",
                            "Edit, delete, or reorder saved circuit results before generating the PDF."
                        ]
                    )

                    AppHelpCard(
                        title: "Entering Measurements",
                        rows: [
                            "Enter measured values exactly as shown on the tester.",
                            "Cable size is entered as the number only. The PDF adds mm².",
                            "Earth continuity and fault loop impedance are recorded in ohms.",
                            "Insulation resistance is recorded in megohms.",
                            "RCD trip time can include decimals, such as 24.4 ms."
                        ]
                    )

                    AppHelpCard(
                        title: "Main Isolator Entries",
                        rows: [
                            "Select Main Isolator when the device is for isolation only.",
                            "Main isolator Zs values are recorded only.",
                            "For three-phase supplies, record A, B, and C phase Zs values where required.",
                            "The PDF will show Record only and Upstream protection to verify."
                        ]
                    )

                    AppHelpCard(
                        title: "Photos and Attachments",
                        rows: [
                            "Use Attachments to add site photos where useful.",
                            "Photos are included after the result pages in the PDF.",
                            "Keep photos relevant to the report, such as boards, labels, defects, or test evidence."
                        ]
                    )

                    AppHelpCard(
                        title: "Preview and PDF Export",
                        rows: [
                            "Open Preview to check the report before exporting.",
                            "Generate PDF creates a named report file for sharing or saving.",
                            "Generated reports are saved in History automatically."
                        ]
                    )

                    AppHelpCard(
                        title: "History and Templates",
                        rows: [
                            "Use History to search, preview, share, archive, or delete reports.",
                            "Use a previous report as a template when starting similar work.",
                            "Templates are useful for repeated sites, boards, or common circuit layouts."
                        ]
                    )

                    AppHelpCard(
                        title: "Backup and Restore",
                        rows: [
                            "Export All Reports creates a backup file containing saved reports and templates.",
                            "Import/Restore Backup loads reports and templates from a backup file.",
                            "Create backups before deleting app data or moving to another device."
                        ]
                    )

                    AppHelpCard(
                        title: "Testing Help & Standards",
                        rows: [
                            "Use Testing Help & Standards for testing reminders and quick field reference.",
                            "Bundled standards are available there for full clauses, tables, and limits."
                        ]
                    )

                    AppHelpCard(
                        title: "Support",
                        rows: [
                            "For support, email info@npcontracting.com.au."
                        ]
                    )
                }
                .padding()
                .padding(.bottom, 96)
            }
            .background(Color.npBackground)
            .navigationTitle("App Help & Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct AppHelpCard: View {
    let title: String
    let rows: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(rows, id: \.self) { row in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.black)
                        Text(row)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.npSecondarySurface)
        .cornerRadius(14)
    }
}

struct PDFToShow: Identifiable, Equatable {
    let name: String
    let title: String
    let searchQueries: [String]

    var id: String {
        [name, title, searchQueries.joined(separator: "|")].joined(separator: "::")
    }
}

struct StandardsView: View {
    @State private var showPDF: PDFToShow?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick reference for electrical verification, testing, and report entries. Use the bundled standards for full clauses, tables, and limits.")
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Standards")
                        .font(.headline)
                        .foregroundColor(.black)

                    StandardsLinkButton(title: "AS/NZS 3000:2018") {
                        showPDF = PDFToShow(name: "AS3000.pdf", title: "AS/NZS 3000:2018", searchQueries: [])
                    }

                    StandardsLinkButton(title: "AS/NZS 3017:2022") {
                        showPDF = PDFToShow(name: "AS3017.pdf", title: "AS/NZS 3017:2022", searchQueries: [])
                    }

                    StandardsLinkButton(title: "AS/NZS 3008") {
                        showPDF = PDFToShow(name: "AS3008.pdf", title: "AS/NZS 3008", searchQueries: [])
                    }
                }

                TestingHelpCard(
                    title: "Before Testing",
                    rows: [
                        "Confirm safe isolation before dead testing.",
                        "Prove the tester before and after use.",
                        "Check test leads and probes are in good condition.",
                        "Null test leads where required.",
                        "Confirm the correct circuit before recording results.",
                        "Disconnect sensitive equipment before insulation resistance testing where required.",
                        "Do not assume the earth is good until the earthing path has been verified.",
                        "Stop and investigate any reading that is unexpected, unstable, or unsafe."
                    ]
                )

                TestingHelpCard(
                    title: "Test Sequence",
                    rows: [
                        "Visual inspection first.",
                        "Confirm the circuit is de-energized before dead testing.",
                        "Complete dead tests before live tests where applicable.",
                        "Dead tests include earth continuity and insulation resistance.",
                        "Live tests include polarity, correct circuit connections, fault loop impedance, and RCD operation.",
                        "Record the measured value exactly as displayed on the tester.",
                        "Failed or unusual readings must be investigated before sign-off."
                    ]
                )

                TestingHelpCard(
                    title: "Commercial Cable Quick Reference",
                    subtitle: "Guide only. Cable selection must be verified against AS/NZS 3008, project specifications, installation method, grouping, correction factors, load, route length, voltage drop, and fault current.\n\nCommercial / hospital common practice:",
                    rows: [
                        "2.5 mm²: commonly lighting and control circuits.",
                        "4 mm²: commonly general power circuits.",
                        "6 mm² and above: larger loads, submains, mechanical plant, HVAC, and longer runs.",
                        "Domestic comparison:",
                        "1.5 mm² is commonly domestic lighting.",
                        "2.5 mm² is commonly domestic power.",
                        "Voltage drop reminders:",
                        "Longer route length increases voltage drop.",
                        "Higher current increases voltage drop.",
                        "2.5 mm² on a 20A final subcircuit becomes a warning point around 30 m.",
                        "4 mm² gives more margin for commercial power circuits.",
                        "If the run is long, heavily loaded, grouped, hot, or borderline, calculate it properly."
                    ]
                )

                TestingHelpCard(
                    title: "Earth Continuity",
                    subtitle: "Purpose:\nConfirms the protective earthing conductor is continuous.\n\nRecord:\nMeasured resistance in ohms.\n\nGood result:\nLow and stable resistance.\n\nIf high or unstable, check:",
                    rows: [
                        "loose earth terminals",
                        "damaged protective earthing conductor",
                        "poor test lead contact",
                        "paint, corrosion, or loose bonding point",
                        "incorrect earth bar or circuit",
                        "long route length",
                        "small or damaged earthing conductor"
                    ]
                )

                TestingHelpCard(
                    title: "Insulation Resistance",
                    subtitle: "Purpose:\nConfirms insulation is sound between conductors and earth.\n\nRecord:\nInsulation resistance in megohms.\n\nCommon checks:",
                    rows: [
                        "Active to Earth",
                        "Neutral to Earth",
                        "Active to Neutral where suitable",
                        "Three phase checks between A, B, C, Neutral, and Earth where required",
                        "If low or failed, check:",
                        "connected appliances or equipment",
                        "surge protection devices",
                        "electronic equipment",
                        "damp fittings or cables",
                        "damaged insulation",
                        "shared or borrowed neutrals",
                        "incorrect circuit separation"
                    ]
                )

                TestingHelpCard(
                    title: "Incoming Supply / Neutral Verification",
                    subtitle: "Purpose:\nConfirms incoming active, neutral, and earth references are correctly identified.\n\nUse an independent earth reference where required.\n\nTypical live readings:",
                    rows: [
                        "Active to Neutral: about 230 V",
                        "Active to Earth: about 230 V",
                        "Neutral to Earth: close to 0 V",
                        "Three phase:",
                        "Phase to Phase: about 400/415 V",
                        "Phase to Neutral: about 230/240 V",
                        "Neutral to Earth: close to 0 V",
                        "If Neutral to Earth voltage is high or unstable:",
                        "check for high resistance neutral",
                        "check neutral connections",
                        "check MEN connection where applicable",
                        "investigate before energizing connected circuits"
                    ]
                )

                TestingHelpCard(
                    title: "Polarity / Correct Connection",
                    subtitle: "Purpose:\nConfirms active, neutral, earth, switches, circuit breakers, and socket outlets are correctly connected.\n\nRecord:\nPass or fail.\n\nIf failed, check:",
                    rows: [
                        "active and neutral reversed",
                        "switch controlling neutral instead of active",
                        "incorrect socket outlet polarity",
                        "neutral in wrong bar",
                        "active in wrong breaker",
                        "circuit conductors mixed between circuits",
                        "incorrect circuit labelling"
                    ]
                )

                TestingHelpCard(
                    title: "Interconnected Circuit Check",
                    subtitle: "Purpose:\nChecks that separate circuits are not unintentionally connected together.\n\nDead method:",
                    rows: [
                        "Isolate supply.",
                        "Test continuity between separate circuits.",
                        "Investigate unexpected continuity.",
                        "Live method:",
                        "Energize one circuit at a time.",
                        "Confirm other isolated circuits do not become live.",
                        "Repeat for remaining circuits.",
                        "If unexpected voltage or continuity appears, check:",
                        "shared or borrowed neutrals",
                        "incorrect active links",
                        "relay or contactor wiring",
                        "emergency lighting wiring",
                        "two-way or intermediate switching",
                        "incorrect circuit identification",
                        "incorrect labelling"
                    ]
                )

                TestingHelpCard(
                    title: "Fault Loop Impedance / Zs",
                    subtitle: "Purpose:\nConfirms the fault path is low enough for the protective device to disconnect within the required time.\n\nRecord:\nMeasured Zs in ohms.\n\nIf Zs is too high, check:",
                    rows: [
                        "loose active terminal",
                        "loose earth terminal",
                        "long route length",
                        "undersized or damaged earthing conductor",
                        "high resistance joints",
                        "poor MEN or earthing connection",
                        "wrong breaker rating",
                        "wrong breaker curve",
                        "poor test lead contact",
                        "upstream protection arrangement"
                    ]
                )

                TestingHelpCard(
                    title: "Disconnection Time",
                    subtitle: "Purpose:\nUsed with Zs to confirm the protective device can disconnect quickly enough under fault conditions.\n\nQuick reference:",
                    rows: [
                        "0.4 s: most 230 V final subcircuits.",
                        "5.0 s: many submains and distribution circuits where permitted.",
                        "Breaker curve B/C/D affects maximum permitted Zs.",
                        "Disconnection time is selected from the circuit type and protection arrangement."
                    ]
                )

                TestingHelpCard(
                    title: "RCD Test",
                    subtitle: "Purpose:\nConfirms the RCD or RCBO operates correctly.\n\nRecord:",
                    rows: [
                        "device rating",
                        "pass/fail result",
                        "trip time in milliseconds",
                        "If failed, check:",
                        "correct tester setting",
                        "correct RCD selected",
                        "line and load wiring",
                        "shared or borrowed neutral",
                        "supply present",
                        "incorrect circuit connected to RCD",
                        "faulty RCD or RCBO"
                    ]
                )

                TestingHelpCard(
                    title: "Main Isolator",
                    subtitle: "Purpose:\nRecords mains or main switch test values where the device is used for isolation.\n\nImportant:",
                    rows: [
                        "A main isolator is not the same as a circuit breaker.",
                        "A main isolator does not provide automatic fault disconnection.",
                        "Record measured values only.",
                        "Verify the upstream protective device where fault protection is required."
                    ]
                )

                TestingHelpCard(
                    title: "When a Result Fails",
                    rows: [
                        "Do not overwrite failed readings without investigation.",
                        "Check:",
                        "correct test method selected",
                        "correct circuit selected",
                        "correct breaker rating",
                        "correct breaker type or curve",
                        "test leads nulled",
                        "terminals tight",
                        "equipment disconnected where required",
                        "no shared or borrowed neutrals",
                        "upstream protection arrangement",
                        "result repeated and confirmed"
                    ]
                )
            }
            .padding()
            .padding(.bottom, 96)
        }
        .navigationTitle("Testing Help & Standards")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $showPDF) { pdfToShow in
            StandardsPDFViewer(
                pdfName: pdfToShow.name,
                referenceTitle: pdfToShow.title,
                initialSearchQueries: pdfToShow.searchQueries
            )
        }
    }

    private func openReference(pdfName: String, title: String, searchQueries: [String]) {
        showPDF = PDFToShow(name: pdfName, title: title, searchQueries: searchQueries)
    }
}

private struct StandardsLinkButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "doc.text")
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.npBrandYellow)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

private struct TestingHelpCard: View {
    let title: String
    var subtitle: String? = nil
    let rows: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)

            if let subtitle {
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(rows, id: \.self) { row in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.black)
                        Text(row)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.npSecondarySurface)
        .cornerRadius(14)
    }
}

struct StandardsPDFViewer: View {
    let pdfName: String
    let referenceTitle: String
    let initialSearchQueries: [String]

    @State private var searchText = ""
    @State private var pdfDocument: PDFDocument?
    @State private var searchResults: [PDFSelection] = []
    @State private var currentResultIndex = 0
    @State private var bookmarks: [Int: String] = [:]
    @State private var showBookmarks = false
    @State private var didApplyInitialSearch = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !referenceTitle.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(referenceTitle)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if !initialSearchQueries.isEmpty {
                            Text("Auto-searching the bundled PDF for the closest matching table or clause.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 12)
                }

                HStack {
                    TextField("Search", text: $searchText, onCommit: search)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding([.horizontal, .top])

                    if !searchResults.isEmpty {
                        Button(action: previousResult) { Image(systemName: "chevron.up") }
                        Text("\(currentResultIndex + 1)/\(searchResults.count)")
                            .font(.caption)
                            .frame(minWidth: 40)
                        Button(action: nextResult) { Image(systemName: "chevron.down") }
                    }

                    Button(action: { showBookmarks = true }) {
                        Image(systemName: "bookmark")
                    }

                    Button("Close") { dismiss() }
                        .padding(.trailing)
                }

                Divider()

                if let pdfDocument {
                    PDFKitRepresentedViewWithHighlight(
                        pdfDocument: pdfDocument,
                        selection: currentSelection,
                        onBookmark: addOrRemoveBookmark,
                        bookmarks: bookmarks,
                        goToPage: goToPage
                    )
                } else {
                    Text("PDF not found.")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if let url = bundledPDFURL(named: pdfName) {
                    let document = PDFDocument(url: url)
                    pdfDocument = document
                    applyInitialSearchIfNeeded(using: document)
                }
            }
            .sheet(isPresented: $showBookmarks) {
                NavigationView {
                    List {
                        ForEach(bookmarks.sorted(by: { $0.key < $1.key }), id: \.key) { page, label in
                            Button(action: {
                                goToPage(page)
                                showBookmarks = false
                            }) {
                                HStack {
                                    Text("Page \(page + 1)")
                                    if !label.isEmpty {
                                        Text(": \(label)")
                                    }
                                }
                            }
                        }
                        .onDelete { indices in
                            for index in indices {
                                let key = Array(bookmarks.keys.sorted())[index]
                                bookmarks.removeValue(forKey: key)
                            }
                        }
                    }
                    .navigationTitle("Bookmarks")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showBookmarks = false }
                        }
                    }
                }
            }
        }
    }

    var currentSelection: PDFSelection? {
        guard !searchResults.isEmpty, currentResultIndex < searchResults.count else { return nil }
        return searchResults[currentResultIndex]
    }

    func search() {
        guard let pdfDocument, !searchText.isEmpty else {
            searchResults = []
            currentResultIndex = 0
            return
        }

        let results = pdfDocument.findString(searchText, withOptions: .caseInsensitive)
        searchResults = results
        currentResultIndex = 0

        for selection in results {
            selection.color = .yellow
        }
    }

    func applyInitialSearchIfNeeded(using document: PDFDocument?) {
        guard !didApplyInitialSearch else { return }
        didApplyInitialSearch = true

        guard let document, !initialSearchQueries.isEmpty else { return }

        for query in initialSearchQueries {
            let results = document.findString(query, withOptions: .caseInsensitive)
            if !results.isEmpty {
                searchText = query
                searchResults = results
                currentResultIndex = 0
                for selection in results { selection.color = .yellow }
                return
            }
        }

        searchText = initialSearchQueries[0]
        searchResults = []
        currentResultIndex = 0
    }

    func nextResult() {
        guard !searchResults.isEmpty else { return }
        currentResultIndex = (currentResultIndex + 1) % searchResults.count
    }

    func previousResult() {
        guard !searchResults.isEmpty else { return }
        currentResultIndex = (currentResultIndex - 1 + searchResults.count) % searchResults.count
    }

    func addOrRemoveBookmark(page: Int, label: String = "") {
        if bookmarks[page] != nil {
            bookmarks.removeValue(forKey: page)
        } else {
            bookmarks[page] = label
        }
    }

    func goToPage(_ page: Int) {
        guard let pdfDocument, let pdfView = PDFKitRepresentedViewWithHighlight.lastPDFView else { return }
        if let pageObject = pdfDocument.page(at: page) {
            pdfView.go(to: pageObject)
        }
    }

    private func bundledPDFURL(named fileName: String) -> URL? {
        let resourceName = fileName.replacingOccurrences(of: ".pdf", with: "")

        if let rootURL = Bundle.main.url(forResource: resourceName, withExtension: "pdf") {
            return rootURL
        }

        return Bundle.main.url(forResource: resourceName, withExtension: "pdf", subdirectory: "Resources")
    }
}

struct PDFKitRepresentedViewWithHighlight: UIViewRepresentable {
    let pdfDocument: PDFDocument
    let selection: PDFSelection?
    let onBookmark: (Int, String) -> Void
    let bookmarks: [Int: String]
    let goToPage: (Int) -> Void

    static var lastPDFView: PDFView?

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        Self.lastPDFView = pdfView
        addBookmarkButton(to: pdfView, context: context)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = pdfDocument
        if let selection, !selection.pages.isEmpty {
            pdfView.go(to: selection)
            pdfView.setCurrentSelection(selection, animate: true)
            pdfView.highlightedSelections = [selection]
        } else {
            pdfView.highlightedSelections = nil
        }
        addBookmarkButton(to: pdfView, context: context)
    }

    private func addBookmarkButton(to pdfView: PDFView, context: Context) {
        pdfView.subviews
            .filter { $0 is UIButton && $0.tag == 9999 }
            .forEach { $0.removeFromSuperview() }

        let button = UIButton(type: .system)
        button.setTitle("Bookmark", for: .normal)
        button.tag = 9999
        button.addTarget(context.coordinator, action: #selector(Coordinator.bookmarkTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        pdfView.addSubview(button)

        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: pdfView.trailingAnchor, constant: -16),
            button.topAnchor.constraint(equalTo: pdfView.topAnchor, constant: 16)
        ])

        context.coordinator.onBookmark = onBookmark
        context.coordinator.pdfView = pdfView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject {
        var onBookmark: ((Int, String) -> Void)?
        weak var pdfView: PDFView?

        @objc func bookmarkTapped() {
            guard
                let pdfView,
                let page = pdfView.currentPage,
                let pageIndex = pdfView.document?.index(for: page)
            else {
                return
            }
            onBookmark?(pageIndex, "")
        }
    }
}
