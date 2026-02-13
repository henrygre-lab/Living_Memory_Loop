import SwiftUI

struct MemoryCard: View {
    let memory: Memory
    let index: Int
    let onTap: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    private var categoryStyle: AppColors.CategoryStyle {
        AppColors.categoryStyle(for: memory.category)
    }

    private var moodColor: Color {
        AppColors.moodColor(for: memory.mood)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text(memory.category.uppercased())
                    .font(AppTypography.cardCategory)
                    .foregroundStyle(categoryStyle.text)
                    .tracking(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(categoryStyle.background)
                    .clipShape(Capsule())

                Spacer()

                Text(TimeFormatting.timeAgo(from: memory.createdAt))
                    .font(AppTypography.cardMeta)
                    .foregroundStyle(AppColors.steelBlue)
            }
            .padding(.bottom, 12)

            Text(memory.title)
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.text)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 8)

            if !memory.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(memory.actionItems.prefix(2).enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(AppColors.steelBlue)
                                .frame(width: 4, height: 4)
                                .padding(.top, 8)

                            Text(item)
                                .font(AppTypography.cardAction)
                                .foregroundStyle(AppColors.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    if memory.actionItems.count > 2 {
                        Text("+\(memory.actionItems.count - 2) more")
                            .font(AppTypography.cardMore)
                            .foregroundStyle(AppColors.steelBlue)
                            .padding(.leading, 14)
                            .padding(.top, 2)
                    }
                }
                .padding(.bottom, 12)
            }

            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(moodColor)
                        .frame(width: 6, height: 6)

                    Text(memory.mood)
                        .font(AppTypography.cardMood)
                        .foregroundStyle(AppColors.navy)
                        .italic()
                }

                Spacer()

                HStack(spacing: 12) {
                    Button(action: onPin) {
                        Image(systemName: memory.pinned ? "star.fill" : "star")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(memory.pinned ? AppColors.pinColor : AppColors.steelBlue)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .liquidGlass()

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(AppColors.steelBlue)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .liquidGlass()
                }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(AppColors.cardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppColors.navy.opacity(0.06), radius: 10, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(
            .spring(response: 0.5, dampingFraction: 0.85).delay(Double(index) * 0.06),
            value: memory.id
        )
    }
}
