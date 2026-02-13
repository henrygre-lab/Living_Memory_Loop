import SwiftUI
import UIKit

struct MemoryDetailScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MemoryStore.self) private var memoryStore

    let memoryId: String

    @State private var showShareSheet = false
    @State private var showDeleteAlert = false
    @State private var showActionItemsSection = false
    @State private var showTranscriptSection = false

    private var memory: Memory? {
        memoryStore.getMemory(id: memoryId)
    }

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE, MMMM d, yyyy, h:mm a"
        return formatter
    }()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                topBar
                content
            }

            favoriteButton
                .padding(.trailing, 24)
                .padding(.bottom, 28)
        }
        .background(AppColors.background.ignoresSafeArea())
        .sheet(isPresented: $showShareSheet) {
            if let memory {
                ShareSheet(activityItems: [shareText(for: memory)])
            }
        }
        .alert("Delete Memory", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                guard let memory else {
                    dismiss()
                    return
                }

                HapticHelper.notification(.warning)
                Task {
                    await memoryStore.removeMemory(id: memory.id)
                    dismiss()
                }
            }
        } message: {
            if let title = memory?.title {
                Text("Remove \"\(title)\"?")
            } else {
                Text("This memory no longer exists.")
            }
        }
        .onAppear {
            animateSections()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                HapticHelper.impact(.light)
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(AppColors.navy)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(AppColors.backgroundPure)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 8) {
                Button {
                    HapticHelper.impact(.light)
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(AppColors.steelBlue)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(AppColors.backgroundPure)
                        )
                }
                .buttonStyle(.plain)
                .disabled(memory == nil)

                Button {
                    HapticHelper.impact(.light)
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(AppColors.danger)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(AppColors.backgroundPure)
                        )
                }
                .buttonStyle(.plain)
                .disabled(memory == nil)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(AppColors.backgroundPure)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 0.5)
        }
    }

    private var favoriteButton: some View {
        Button {
            guard let memory else { return }
            HapticHelper.impact(.light)
            Task {
                await memoryStore.togglePin(id: memory.id)
            }
        } label: {
            Image(systemName: (memory?.pinned ?? false) ? "star.fill" : "star")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle((memory?.pinned ?? false) ? AppColors.pinColor : AppColors.steelBlue)
                .frame(width: 58, height: 58)
                .background(
                    Circle()
                        .fill(AppColors.backgroundPure)
                )
                .shadow(color: AppColors.navy.opacity(0.08), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(memory == nil)
    }

    @ViewBuilder
    private var content: some View {
        if let memory {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    metaRow(for: memory)
                        .padding(.bottom, 20)

                    Text(memory.title)
                        .font(.custom(AppFonts.interBold, size: 28))
                        .foregroundStyle(AppColors.text)
                        .tracking(0.5)
                        .lineSpacing(6)
                        .padding(.bottom, 8)

                    Text(Self.fullDateFormatter.string(from: memory.createdAt))
                        .font(.custom(AppFonts.interRegular, size: 13))
                        .foregroundStyle(AppColors.steelBlue)
                        .padding(.bottom, 20)

                    Rectangle()
                        .fill(AppColors.lightBlue.opacity(0.9))
                        .frame(height: 1)
                        .padding(.bottom, 24)

                    if !memory.actionItems.isEmpty {
                        actionItemsSection(for: memory)
                            .opacity(showActionItemsSection ? 1 : 0)
                            .offset(y: showActionItemsSection ? 0 : 8)
                            .padding(.bottom, 28)
                    }

                    transcriptSection(for: memory)
                        .opacity(showTranscriptSection ? 1 : 0)
                        .offset(y: showTranscriptSection ? 0 : 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        } else {
            VStack(spacing: 12) {
                Text("Memory not found")
                    .font(.custom(AppFonts.interSemiBold, size: 18))
                    .foregroundStyle(AppColors.navy)

                Text("This memory may have been deleted.")
                    .font(.custom(AppFonts.interRegular, size: 14))
                    .foregroundStyle(AppColors.steelBlue)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, 24)
        }
    }

    private func metaRow(for memory: Memory) -> some View {
        let categoryStyle = AppColors.categoryStyle(for: memory.category)

        return HStack(spacing: 12) {
            Text(memory.category.uppercased())
                .font(.custom(AppFonts.interSemiBold, size: 11))
                .foregroundStyle(categoryStyle.text)
                .tracking(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(categoryStyle.background)
                .clipShape(Capsule())

            HStack(spacing: 6) {
                Circle()
                    .fill(AppColors.moodColor(for: memory.mood))
                    .frame(width: 7, height: 7)

                Text(memory.mood)
                    .font(.custom(AppFonts.interRegular, size: 13))
                    .foregroundStyle(AppColors.navy)
                    .italic()
            }

            Spacer()
        }
    }

    private func actionItemsSection(for memory: Memory) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ACTION ITEMS")
                .font(.custom(AppFonts.interSemiBold, size: 11))
                .foregroundStyle(AppColors.steelBlue)
                .tracking(2)
                .padding(.bottom, 14)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(memory.actionItems.enumerated()), id: \.offset) { index, item in
                    actionItemRow(memory: memory, index: index, item: item)
                }
            }
        }
    }

    private func actionItemRow(memory: Memory, index: Int, item: String) -> some View {
        let isCompleted = memory.completedItems.contains(index)

        return Button {
            HapticHelper.impact(.light)
            Task {
                await memoryStore.toggleActionItem(memoryId: memory.id, index: index)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isCompleted ? AppColors.turquoise : AppColors.lightBlue, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isCompleted ? AppColors.turquoise : Color.clear)
                        )

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.backgroundPure)
                    }
                }
                .padding(.top, 1)

                Text(item)
                    .font(.custom(AppFonts.interRegular, size: 15))
                    .foregroundStyle(isCompleted ? AppColors.steelBlue.opacity(0.6) : AppColors.textSecondary)
                    .strikethrough(isCompleted, color: AppColors.steelBlue.opacity(0.6))
                    .lineSpacing(3)
                    .padding(.top, 3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func transcriptSection(for memory: Memory) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TRANSCRIPT")
                .font(.custom(AppFonts.interSemiBold, size: 11))
                .foregroundStyle(AppColors.steelBlue)
                .tracking(2)
                .padding(.bottom, 14)

            Text(memory.transcript.isEmpty ? "No transcript available." : memory.transcript)
                .font(.custom(AppFonts.interRegular, size: 14))
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(6)
                .italic()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.backgroundPure.opacity(0.82))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.lightBlue.opacity(0.75), lineWidth: 1)
                )
                .shadow(color: AppColors.navy.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }

    private func shareText(for memory: Memory) -> String {
        let actionItemsBlock: String
        if memory.actionItems.isEmpty {
            actionItemsBlock = "Action Items:\n  - None"
        } else {
            let lines = memory.actionItems.map { "  - \($0)" }.joined(separator: "\n")
            actionItemsBlock = "Action Items:\n\(lines)"
        }

        return [
            memory.title,
            "Category: \(memory.category)\nMood: \(memory.mood)",
            actionItemsBlock,
            "\"\(memory.transcript)\"",
        ].joined(separator: "\n\n")
    }

    private func animateSections() {
        showActionItemsSection = false
        showTranscriptSection = false

        withAnimation(.easeOut(duration: 0.28).delay(0.1)) {
            showActionItemsSection = true
        }

        withAnimation(.easeOut(duration: 0.28).delay(0.2)) {
            showTranscriptSection = true
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let store = MemoryStore(
        memories: [
            Memory(
                title: "Morning Sprint Plan",
                category: "Work",
                actionItems: ["Send API update", "Review PR #42", "Schedule design sync"],
                completedItems: [1],
                mood: "determined",
                transcript: "Need to send update and review that PR today.",
                createdAt: .now.addingTimeInterval(-2_400),
                pinned: true
            ),
        ],
        isLoading: false
    )

    MemoryDetailScreen(memoryId: store.memories[0].id)
        .environment(store)
}
