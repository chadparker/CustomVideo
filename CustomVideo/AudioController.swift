import AVFoundation.AVFAudio

class AudioController {

    // MARK: - Identifiers

    enum AudioEngineError: Error {
        case fileFormatError
    }

    // MARK: - Properties

    private(set) var isRecording = false
    private(set) var recordedFileURL = URL(
        fileURLWithPath: "input.caf",
        isDirectory: false,
        relativeTo: URL(fileURLWithPath: NSTemporaryDirectory())
    )
    private var audioEngine = AVAudioEngine()
    private var isNewRecordingAvailable = false
    private var audioFormat: AVAudioFormat
    private var recordedFile: AVAudioFile?

    // MARK: - Init

    init() throws {
        guard let audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48000,
            channels: 1,
            interleaved: true
        ) else {
            throw AudioEngineError.fileFormatError
        }
        self.audioFormat = audioFormat

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, options: .defaultToSpeaker)
        try session.setPreferredSampleRate(audioFormat.sampleRate)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configChanged(_:)),
            name: .AVAudioEngineConfigurationChange,
            object: audioEngine
        )
    }

    // MARK: - Actions

    @objc func configChanged(_ notification: Notification) {
        try? ensureEngineIsRunning()
    }

    // MARK: - Methods

    func setup() throws {
        let input = audioEngine.inputNode
        try input.setVoiceProcessingEnabled(true)

        audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: audioFormat)

        input.installTap(onBus: 0, bufferSize: 256, format: audioFormat) { buffer, when in
            if self.isRecording {
                do {
                    try self.recordedFile?.write(from: buffer)
                } catch {
                    print("Could not write buffer: \(error)")
                }
                //self.voiceIOPowerMeter.process(buffer: buffer)
            } else {
                //self.voiceIOPowerMeter.processSilence()
            }
        }
        audioEngine.prepare()
    }

    func start() throws {
        try audioEngine.start()
    }

    func ensureEngineIsRunning() throws {
        if !audioEngine.isRunning {
            try start()
        }
    }

    func startRecording() throws {
        recordedFile = try AVAudioFile(forWriting: recordedFileURL, settings: audioFormat.settings)
        isNewRecordingAvailable = true
        isRecording = true
    }

    func stopRecording() {
        isRecording = false
        recordedFile = nil // close file
    }
}
