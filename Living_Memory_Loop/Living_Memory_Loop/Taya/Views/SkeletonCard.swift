import SwiftUI

struct SkeletonCard: View {
    @State private var shimmerOffset: CGFloat = -240
    @State private var pulseOpacity = 0.3

    var body: some View {
        ZStack {
            cardShell

            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            AppColors.backgroundPure.opacity(0.5),
                            .clear,
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 120)
                .offset(x: shimmerOffset)
                .blendMode(.plusLighter)
                .mask(
                    RoundedRectangle(cornerRadius: 16)
                        .frame(height: 212)
                )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseOpacity = 1.0
            }
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                shimmerOffset = 240
            }
        }
    }

    private var cardShell: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                skeletonBlock(width: 80, height: 20, cornerRadius: 10)
                Spacer()
                skeletonBlock(width: 50, height: 14, cornerRadius: 6)
            }
            .padding(.bottom, 16)

            skeletonBlock(width: 230, height: 18, cornerRadius: 6)
                .padding(.bottom, 8)
            skeletonBlock(width: 150, height: 18, cornerRadius: 6)
                .padding(.bottom, 14)

            skeletonBlock(width: 280, height: 14, cornerRadius: 6)
                .padding(.bottom, 6)
            skeletonBlock(width: 190, height: 14, cornerRadius: 6)
                .padding(.bottom, 14)

            skeletonBlock(width: 70, height: 14, cornerRadius: 6)
        }
        .padding(20)
        .frame(maxWidth: 360)
        .background(AppColors.cardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(pulseOpacity)
    }

    private func skeletonBlock(width: CGFloat, height: CGFloat, cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AppColors.backgroundTertiary)
            .frame(width: width, height: height)
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        SkeletonCard()
            .padding(.horizontal, 24)
    }
}
