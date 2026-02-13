import SwiftUI

struct TayaApp: App {
    @State private var memoryStore = MemoryStore()

    var body: some Scene {
        WindowGroup {
            HomeScreen()
                .environment(memoryStore)
                .task {
                    await memoryStore.loadMemories()
                }
        }
    }
}
