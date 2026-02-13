import SwiftUI

private enum RecordScreenState {
    case idle
    case recording
    case processing
    case error
}

struct RecordScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MemoryStore.self) private var memoryStore

    @State private var recorder = AudioRecorderService()
    @State private var screenState: RecordScreenState = .idle
    @State private var errorMessage = ""
    @State private var isProcessing = false
    @State private var didTriggerStopOnPressDown = false
    @State private var autoStopTask: Task<Void, Never>?
    @State private var processingGuardTask: Task<Void, Never>?
    @State private var processTask: Task<Void, Never>?

    private let onMemoryCreated: ((String) -> Void)?
    private let maxRecordingSeconds: TimeInterval = 60

    init(onMemoryCreated: ((String) -> Void)? = nil) {
        self.onMemoryCreated = onMemoryCreated
    }

    private var isRecording: Bool {
        screenState == .recording
    }

    private var durationText: String {
        let seconds = Int(recorder.duration)
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%d:%02d", minutes, remainder)
    }

    private var recordingGradient: LinearGradient {
        LinearGradient(
            colors: [AppColors.background, AppColors.lightBlue, AppColors.navy],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack {
            if isRecording {
                recordingGradient.ignoresSafeArea()
            } else {
                AppColors.background.ignoresSafeArea()
            }

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                Spacer()

                content
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: screenState)

                Spacer()

                privacyNote
                    .padding(.bottom, 16)
            }
            .padding(.bottom, 8)
        }
        .onDisappear {
            cancelAllTasks()
            recorder.cancelRecording()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                HapticHelper.impact(.light)
                closeScreen()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(AppColors.navy)
                    .frame(width: 40, height: 40)
            }
            .liquidGlass()

            Spacer()

            if isRecording {
                Text(durationText)
                    .font(.custom(AppFonts.interMedium, size: 16))
                    .foregroundStyle(AppColors.navy)
                    .tracking(1)
                    .padding(.trailing, 6)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isRecording ? AppColors.background.opacity(0.85) : .clear)
        )
        .padding(.horizontal, isRecording ? 12 : 0)
    }

    @ViewBuilder
    private var content: some View {
        switch screenState {
        case .processing:
            processingView
        case .error:
            errorView
        case .idle, .recording:
            recordingView
        }
    }

    private var recordingView: some View {
        VStack(spacing: 0) {
            VoiceOrb(isRecording: isRecording, amplitude: recorder.amplitude)
                .padding(.bottom, 32)

            VStack(spacing: 8) {
                Text(isRecording ? "LISTENING..." : "TAP TO CAPTURE")
                    .font(.custom(AppFonts.interSemiBold, size: 13))
                    .foregroundStyle(isRecording ? AppColors.turquoise : AppColors.steelBlue)
                    .tracking(3)

                Text(isRecording ? "Tap again when finished" : "Speak your thought naturally")
                    .font(AppTypography.body)
                    .foregroundStyle(isRecording ? AppColors.backgroundPure.opacity(0.7) : AppColors.steelBlue)
            }
            .padding(.bottom, 32)

            if isRecording {
                stopButton
            } else {
                startButton
            }
        }
        .padding(.horizontal, 24)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var processingView: some View {
        VStack(spacing: 0) {
            Text("Structuring your memory...")
                .font(.custom(AppFonts.interSemiBold, size: 20))
                .foregroundStyle(AppColors.navy)
                .tracking(0.3)
                .padding(.bottom, 8)

            Text("Extracting key ideas and actions")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.steelBlue)

            SkeletonCard()
                .padding(.top, 40)
        }
        .padding(.horizontal, 24)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var errorView: some View {
        VStack(spacing: 0) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.danger)
                .padding(.bottom, 16)

            Text("Something went wrong")
                .font(.custom(AppFonts.interSemiBold, size: 20))
                .foregroundStyle(AppColors.text)
                .padding(.bottom, 8)

            Text(errorMessage)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.steelBlue)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

            Button {
                HapticHelper.impact(.light)
                isProcessing = false
                errorMessage = ""
                screenState = .idle
            } label: {
                Text("Try Again")
                    .font(.custom(AppFonts.interMedium, size: 14))
                    .foregroundStyle(AppColors.backgroundPure)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.navy)
                    .clipShape(Capsule())
            }
            .liquidGlass(.prominent)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var startButton: some View {
        Button {
            HapticHelper.impact(.light)
            startRecording()
        } label: {
            ZStack {
                Circle()
                    .fill(AppColors.backgroundSecondary)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(AppColors.lightBlue, lineWidth: 2)
                    )

                Image(systemName: "mic.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(AppColors.navy)
            }
        }
        .liquidGlass(.prominent)
        .scaleEffect(screenState == .idle ? 1 : 0.94)
        .opacity(screenState == .idle ? 1 : 0.9)
    }

    private var stopButton: some View {
        ZStack {
            Circle()
                .fill(AppColors.backgroundPure.opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(AppColors.danger, lineWidth: 2)
                )

            Image(systemName: "stop.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(AppColors.danger)
        }
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !didTriggerStopOnPressDown else { return }
                    didTriggerStopOnPressDown = true
                    stopRecording()
                }
                .onEnded { _ in
                    didTriggerStopOnPressDown = false
                }
        )
    }

    private var privacyNote: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(isRecording ? AppColors.backgroundPure.opacity(0.5) : AppColors.steelBlue)

            Text("Processed via OpenAI API")
                .font(.custom(AppFonts.interRegular, size: 10))
                .foregroundStyle(isRecording ? AppColors.backgroundPure.opacity(0.5) : AppColors.steelBlue)
                .tracking(0.5)
        }
    }

    private func startRecording() {
        guard !isProcessing else { return }

        Task {
            let granted = await recorder.requestPermission()
            guard granted else {
                HapticHelper.notification(.error)
                errorMessage = "Microphone permission is required. Please enable it in Settings."
                screenState = .error
                return
            }

            do {
                try await recorder.startRecording()
                HapticHelper.impact(.medium)
                errorMessage = ""
                screenState = .recording
                scheduleAutoStop()
            } catch {
                HapticHelper.notification(.error)
                errorMessage = mapStartError(error)
                screenState = .error
            }
        }
    }

    private func stopRecording() {
        guard !isProcessing else { return }
        isProcessing = true
        screenState = .processing
        cancelAutoStop()
        HapticHelper.impact(.heavy)
        startProcessingGuard()

        processTask?.cancel()
        processTask = Task {
            do {
                let audioData = try await recorder.stopRecording()
                let audioBase64 = try await Task.detached(priority: .userInitiated) {
                    audioData.base64EncodedString()
                }.value

                let client = try APIClient()
                let response = try await client.processMemory(audioBase64: audioBase64)

                let memory = Memory(
                    title: response.title,
                    category: response.category,
                    actionItems: response.actionItems,
                    completedItems: [],
                    mood: response.mood,
                    transcript: response.transcript,
                    createdAt: .now,
                    pinned: false
                )

                await memoryStore.addMemory(memory)

                cancelProcessingGuard()
                isProcessing = false
                processTask = nil
                HapticHelper.notification(.success)
                await MainActor.run {
                    onMemoryCreated?(memory.id)
                    dismiss()
                }
            } catch is CancellationError {
                cancelProcessingGuard()
                isProcessing = false
                processTask = nil
                // Cancellation is expected when the timeout guard or close action cancels work.
                return
            } catch {
                cancelProcessingGuard()
                isProcessing = false
                processTask = nil
                HapticHelper.notification(.error)
                errorMessage = mapProcessError(error)
                screenState = .error
            }
        }
    }

    private func closeScreen() {
        cancelAllTasks()
        recorder.cancelRecording()
        dismiss()
    }

    private func scheduleAutoStop() {
        cancelAutoStop()
        autoStopTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(maxRecordingSeconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if screenState == .recording {
                    stopRecording()
                }
            }
        }
    }

    private func cancelAutoStop() {
        autoStopTask?.cancel()
        autoStopTask = nil
    }

    private func startProcessingGuard() {
        cancelProcessingGuard()
        processingGuardTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if isProcessing {
                    isProcessing = false
                    processTask?.cancel()
                    processTask = nil
                    recorder.cancelRecording()
                    errorMessage = "Processing took too long. Please try again."
                    screenState = .error
                }
            }
        }
    }

    private func cancelProcessingGuard() {
        processingGuardTask?.cancel()
        processingGuardTask = nil
    }

    private func cancelAllTasks() {
        cancelAutoStop()
        cancelProcessingGuard()
        processTask?.cancel()
        processTask = nil
    }

    private func mapStartError(_ error: Error) -> String {
        let text = error.localizedDescription.lowercased()

        if text.contains("permission") {
            return "Microphone permission is required. Please enable it in Settings."
        }
        if text.contains("prepare") || text.contains("session") || text.contains("already") {
            return "Audio session conflict. Please close the app fully and reopen it."
        }
        if text.contains("mode") || text.contains("disabled") {
            return "Could not enable recording mode. Please restart the app and try again."
        }
        return "Failed to start recording. Please try again."
    }

    private func mapProcessError(_ error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case let .tooLarge(message):
                return message
            case let .badRequest(message):
                return message
            case let .serverError(message):
                return message
            case let .transport(message):
                let lowered = message.lowercased()
                if lowered.contains("timed out") || lowered.contains("offline") || lowered.contains("could not connect") {
                    return "Could not reach the backend. Start the server and set API_BASE_URL if needed."
                }
                return message
            case let .decoding(message):
                return message
            case let .invalidBaseURL(message):
                return message
            case .invalidResponse:
                return "Failed to process your memory. Please try again."
            }
        }

        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !message.isEmpty, message != "(null)" {
            return message
        }
        return "Failed to process your memory. Please try again."
    }
}

#Preview {
    RecordScreen()
        .environment(MemoryStore())
}
