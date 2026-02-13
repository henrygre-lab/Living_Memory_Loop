import SwiftUI

struct HomeScreen: View {
    @Environment(MemoryStore.self) private var memoryStore
    @State private var memoryPendingDelete: Memory?
    @State private var showRecordScreen = false
    @State private var navigationPath: [String] = []
    @State private var pendingRecordedMemoryID: String?

    private var memories: [Memory] {
        memoryStore.sortedMemories
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.bottom, 24)

                        if memoryStore.isLoading {
                            ProgressView()
                                .tint(AppColors.steelBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 80)
                        } else if memories.isEmpty {
                            EmptyStateView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 80)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(memories.enumerated()), id: \.element.id) { index, memory in
                                    MemoryCard(
                                        memory: memory,
                                        index: index,
                                        onTap: {
                                            HapticHelper.impact(.light)
                                            navigationPath.append(memory.id)
                                        },
                                        onPin: {
                                            HapticHelper.impact(.light)
                                            Task {
                                                await memoryStore.togglePin(id: memory.id)
                                            }
                                        },
                                        onDelete: {
                                            HapticHelper.impact(.light)
                                            memoryPendingDelete = memory
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: memories)
                        }
                    }
                    .padding(.bottom, 120)
                }

                Button {
                    HapticHelper.impact(.medium)
                    showRecordScreen = true
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(AppColors.backgroundPure)
                        .frame(width: 60, height: 60)
                        .background(AppColors.navy)
                        .clipShape(Circle())
                }
                .liquidGlass(.prominent)
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { memoryId in
                MemoryDetailScreen(memoryId: memoryId)
                    .environment(memoryStore)
                    .navigationBarBackButtonHidden(true)
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .alert(
            "Delete Memory",
            isPresented: Binding(
                get: { memoryPendingDelete != nil },
                set: { isPresented in
                    if !isPresented { memoryPendingDelete = nil }
                }
            ),
            presenting: memoryPendingDelete
        ) { memory in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                HapticHelper.notification(.warning)
                Task {
                    await memoryStore.removeMemory(id: memory.id)
                }
            }
        } message: { memory in
            Text("Remove \"\(memory.title)\"?")
        }
        .alert(
            "Storage Error",
            isPresented: Binding(
                get: { memoryStore.lastErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        memoryStore.clearLastError()
                    }
                }
            )
        ) {
            Button("Retry") {
                HapticHelper.impact(.light)
                memoryStore.clearLastError()
                Task {
                    await memoryStore.refreshMemories()
                }
            }
            Button("OK", role: .cancel) {
                HapticHelper.impact(.light)
                memoryStore.clearLastError()
            }
        } message: {
            Text(memoryStore.lastErrorMessage ?? "Something went wrong.")
        }
        .fullScreenCover(isPresented: $showRecordScreen) {
            RecordScreen { newMemoryID in
                pendingRecordedMemoryID = newMemoryID
            }
                .environment(memoryStore)
        }
        .onChange(of: showRecordScreen) { _, isPresented in
            guard !isPresented, let memoryID = pendingRecordedMemoryID else { return }
            pendingRecordedMemoryID = nil
            navigationPath.append(memoryID)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("T A Y A")
                .font(AppTypography.brand)
                .foregroundStyle(AppColors.navy)
                .tracking(6)

            Text("YOUR MEMORY, STRUCTURED")
                .font(AppTypography.tagline)
                .foregroundStyle(AppColors.steelBlue)
                .tracking(2)
        }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .stroke(AppColors.lightBlue, lineWidth: 1.5)
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(AppColors.backgroundTertiary)
                    .frame(width: 72, height: 72)

                Circle()
                    .fill(AppColors.navy.opacity(0.15))
                    .frame(width: 36, height: 36)
            }
            .padding(.bottom, 28)

            Text("No memories yet")
                .font(AppTypography.emptyTitle)
                .foregroundStyle(AppColors.navy)
                .padding(.bottom, 8)

            Text("Tap the capture button to record your first thought")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.steelBlue)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    let store = MemoryStore(
        memories: [
            Memory(
                title: "Morning Sprint Plan",
                category: "Work",
                actionItems: ["Send API update", "Review PR #42", "Schedule design sync"],
                mood: "determined",
                transcript: "Need to send update and review that PR today.",
                createdAt: .now.addingTimeInterval(-2_400),
                pinned: true
            ),
            Memory(
                title: "Weekend Errands",
                category: "Shopping",
                actionItems: ["Buy milk", "Pick up laundry"],
                mood: "calm",
                transcript: "Remember to pick up groceries and laundry this weekend.",
                createdAt: .now.addingTimeInterval(-86_400),
                pinned: false
            ),
        ],
        isLoading: false
    )
    HomeScreen().environment(store)
}
