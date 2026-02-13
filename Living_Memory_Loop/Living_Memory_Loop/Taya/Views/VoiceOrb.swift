import SwiftUI

struct VoiceOrb: View {
    let isRecording: Bool
    let amplitude: Double

    private let orbSize: CGFloat = 100

    @State private var pulse: CGFloat = 0
    @State private var glow: CGFloat = 0

    private var clampedAmplitude: CGFloat {
        CGFloat(max(0, min(1, amplitude)))
    }

    var body: some View {
        ZStack {
            if isRecording {
                ring(size: orbSize * 2.3, color: AppColors.navy, baseScale: 0.2, amplitudeScale: 0.4, opacityRange: (0.04, 0.10))
                ring(size: orbSize * 1.9, color: AppColors.steelBlue, baseScale: 0.15, amplitudeScale: 0.3, opacityRange: (0.08, 0.18))
                ring(size: orbSize * 1.5, color: AppColors.turquoise, baseScale: 0.10, amplitudeScale: 0.2, opacityRange: (0.12, 0.28))
            }

            Circle()
                .fill(AppColors.backgroundPure)
                .frame(width: orbSize, height: orbSize)
                .overlay(
                    Circle()
                        .stroke(AppColors.lightBlue, lineWidth: 2)
                )
                .shadow(color: AppColors.turquoise.opacity(0.35), radius: 24, x: 0, y: 0)
                .scaleEffect(1 + glow * 0.05 + clampedAmplitude * 0.08)
                .animation(.easeInOut(duration: 0.2), value: clampedAmplitude)
                .animation(.easeInOut(duration: 0.4), value: glow)

            Circle()
                .fill(AppColors.navy)
                .frame(width: orbSize * 0.55, height: orbSize * 0.55)
        }
        .frame(width: orbSize * 2.5, height: orbSize * 2.5)
        .allowsHitTesting(false)
        .onAppear {
            updateAnimation(for: isRecording)
        }
        .onChange(of: isRecording) { _, newValue in
            updateAnimation(for: newValue)
        }
    }

    private func ring(
        size: CGFloat,
        color: Color,
        baseScale: CGFloat,
        amplitudeScale: CGFloat,
        opacityRange: (CGFloat, CGFloat)
    ) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .opacity(opacityRange.0 + (opacityRange.1 - opacityRange.0) * pulse)
            .scaleEffect(1 + baseScale * pulse + amplitudeScale * clampedAmplitude)
            .animation(.easeInOut(duration: 0.2), value: clampedAmplitude)
    }

    private func updateAnimation(for recording: Bool) {
        if recording {
            pulse = 0
            glow = 0

            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulse = 1
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glow = 1
            }
        } else {
            withAnimation(.easeOut(duration: 0.4)) {
                pulse = 0
                glow = 0
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        VoiceOrb(isRecording: true, amplitude: 0.7)
    }
}
