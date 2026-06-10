import SwiftUI
import SwiftData

@main
struct FlameHouseApp: App {
    @State private var container: DIContainer = .production

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .environment(container)
                .modelContainer(container.modelContainer)
        }
    }
}
