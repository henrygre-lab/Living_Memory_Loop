import AVFoundation
import Foundation
import Observation

enum AudioRecorderError: LocalizedError {
    case noRecorder
    case failedToStart

    var errorDescription: String? {
        switch self {
        case .noRecorder:
            return "No active recorder found."
        case .failedToStart:
            return "Failed to start recording."
        }
    }
}

@MainActor
@Observable
final class AudioRecorderService {
    private(set) var isRecording = false
    private(set) var amplitude: Double = 0
    private(set) var duration: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var meteringTimer: Timer?
    private var durationTimer: Timer?

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording() async throws {
        stopTimers()
        try await stopIfNeeded()

        do {
            try await startWithSessionReset(waitNanoseconds: 100_000_000)
        } catch {
            try await startWithSessionReset(waitNanoseconds: 300_000_000)
        }
    }

    func stopRecording() async throws -> Data {
        stopTimers()

        guard let recorder else {
            throw AudioRecorderError.noRecorder
        }

        recorder.stop()
        let fileURL = recorder.url
        self.recorder = nil

        isRecording = false
        amplitude = 0
        duration = 0

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        return try await Task.detached(priority: .userInitiated) {
            try Data(contentsOf: fileURL)
        }.value
    }

    func cancelRecording() {
        stopTimers()
        recorder?.stop()
        recorder = nil
        isRecording = false
        amplitude = 0
        duration = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startWithSessionReset(waitNanoseconds: UInt64) async throws {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        try await Task.sleep(nanoseconds: waitNanoseconds)
        try session.setCategory(.record, mode: .default)
        try session.setActive(true)

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()

        guard recorder.record() else {
            throw AudioRecorderError.failedToStart
        }

        self.recorder = recorder
        isRecording = true
        amplitude = 0
        duration = 0
        startTimers()
    }

    private func startTimers() {
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateMetering()
        }

        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            duration += 1
        }
    }

    private func stopTimers() {
        meteringTimer?.invalidate()
        durationTimer?.invalidate()
        meteringTimer = nil
        durationTimer = nil
    }

    private func updateMetering() {
        guard let recorder else { return }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let normalized = max(0, min(1, (Double(power) + 60) / 60))
        amplitude = normalized
    }

    private func stopIfNeeded() async throws {
        guard recorder != nil else { return }
        _ = try await stopRecording()
    }
}
