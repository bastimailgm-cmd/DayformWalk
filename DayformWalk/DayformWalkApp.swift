import SwiftUI

@main
struct DayformWalkApp: App {
    @StateObject private var model = WalkModel()
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .tint(.walkGreen)
                .onChange(of: phase) { _, value in
                    if value == .active { model.becameActive() }
                    else { model.becameInactive() }
                }
        }
    }
}
