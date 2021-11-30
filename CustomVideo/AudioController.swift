import AVFoundation.AVFAudio

class AudioController {

    // MARK: - Identifiers

    enum AudioEngineError: Error {
        case fileFormatError
    }

    // MARK: - Properties

    var recordedFileURL = URL(
        fileURLWithPath: "input.caf",
        isDirectory: false,
        relativeTo: URL(fileURLWithPath: NSTemporaryDirectory())
    )
    private var audioEngine = AVAudioEngine()
    private var avAudioEngine = AVAudioEngine()
    private var isNewRecordingAvailable = false
    private var audioFormat: AVAudioFormat
    private var recordedFile: AVAudioFile?

    public private(set) var isRecording = false
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
        print("File format: \(String(describing: audioFormat))")

        // Set up session
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: .defaultToSpeaker)
        } catch {
            print("Could not set audio category: \(error.localizedDescription)")
        }
        do {
            try session.setPreferredSampleRate(audioFormat.sampleRate)
        } catch {
            print("Could not set preferred sample rate: \(error.localizedDescription)")
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configChanged(_:)),
            name: .AVAudioEngineConfigurationChange,
            object: avAudioEngine
        )
    }

    // MARK: - Actions

    @objc func configChanged(_ notification: Notification) {
        ensureEngineIsRunning()
    }

    // MARK: - Methods

    func setup() {
        let input = avAudioEngine.inputNode
        do {
            try input.setVoiceProcessingEnabled(true)
        } catch {
            print("Could not enable voice processing \(error)")
            return
        }

        let output = avAudioEngine.outputNode
        let mainMixer = avAudioEngine.mainMixerNode

        audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: audioFormat)
        avAudioEngine.connect(mainMixer, to: output, format: audioFormat)

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
        avAudioEngine.prepare()
    }

    func start() {
        do {
            try avAudioEngine.start()
        } catch {
            print("Could not start audio engine: \(error)")
        }
    }

    func ensureEngineIsRunning() {
        if !avAudioEngine.isRunning {
            start()
        }
    }

    func startRecording() {
        recordedFilePlayer.stop()
        do {
            recordedFile = try AVAudioFile(forWriting: recordedFileURL, settings: audioFormat.settings)
            isNewRecordingAvailable = true
            isRecording = true
        } catch {
            print("Could not create file for recording: \(error)")
        }
    }

    func stopRecording() {
        isRecording = false
        recordedFile = nil // close file
    }
}
