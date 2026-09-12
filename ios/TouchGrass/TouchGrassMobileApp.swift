import EventKit

import FentonDesignSystem
import SwiftUI

@main
struct TouchGrassMobileApp: App {
    @StateObject private var store = WellnessStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .fentonTheme(.neutral)
                .task { await store.refresh() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { store.scheduleRefresh() }
                }
                .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
                    store.scheduleRefresh()
                }
        }
    }
}
