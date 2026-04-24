import SwiftUI

@main
struct NPEReportApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            LaunchContainerView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
