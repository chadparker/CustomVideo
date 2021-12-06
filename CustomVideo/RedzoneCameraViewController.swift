import AVFoundation
import Photos
import RedzoneUI
import UIKit

private extension String {
    static let symbolCameraSwitch = "arrow.triangle.2.circlepath"
    static let symbolMicStandard = "mic.fill"
    static let symbolMicVoiceIsolation = "person.wave.2.fill"
    static let symbolMicWideSpectrum = "waveform.and.mic"
    static let symbolFlashOn = "bolt.fill"
    static let symbolFlashOff = "bolt.slash.fill"

    static let activeMicrophoneMode = "activeMicrophoneMode"
}

private extension UIColor {
    static let circularButtonNormal: UIColor = .white
    static let circularButtonDisabled: UIColor = .gray
    static let circularButtonSelected: UIColor = .redzoneYellow
    static let circularButtonBackground: UIColor = .init(white: 0.3, alpha: 0.5) // use blending mode?
}

private extension UIImage.Configuration {
    static let circularButton = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
}

private extension CGFloat {
    static let mainButtonStackWidth: CGFloat = 106
    static let circularButtonSize: CGFloat = 40
}

extension UIButton {
    static func circularButton() -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: .circularButtonSize)
        button.setBackgroundImage(
            UIImage(systemName: "circle.fill", withConfiguration: config)?
                .withTintColor(.circularButtonBackground, renderingMode: .alwaysOriginal),
            for: .normal
        )
        return button
    }
}

public final class RedzoneCameraViewController: UIViewController, CameraControllerDelegate, UIVideoEditorControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Views

    private lazy var previewView = PreviewView(forAutoLayout: true)

    private lazy var referenceImage = UIImageView(forAutoLayout: true).configure {
//        $0.image = UIImage(named: "IMG_0136")
        $0.image = UIImage(named: "Proposed Record Screen (Buttons Enabled)")
    }

    // main buttons

    private lazy var cameraSwitchButton = UIButton.circularButton().configure {
        $0.setImage(
            UIImage(systemName: .symbolCameraSwitch, withConfiguration: .circularButton)?
                .withTintColor(.circularButtonNormal, renderingMode: .alwaysOriginal),
            for: .normal
        )
        $0.setImage(
            UIImage(systemName: .symbolCameraSwitch, withConfiguration: .circularButton)?
                .withTintColor(.circularButtonDisabled, renderingMode: .alwaysOriginal),
            for: .disabled
        )
        $0.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
    }

    private lazy var recordButton = UIButton(type: .system).configure {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setImage(
            UIImage(named: "Record Button"),
            for: .normal
        )
        $0.setImage(
            UIImage(named: "Recording Stop Button"),
            for: .selected
        )
        $0.setImage(
            UIImage(named: "Record Button")?
                .withTintColor(.circularButtonDisabled, renderingMode: .alwaysTemplate),
            for: .disabled
        )
        $0.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
    }

    private lazy var micModeButton = UIButton.circularButton().configure {
        $0.setImage(
            UIImage(systemName: .symbolMicStandard, withConfiguration: .circularButton)?
                .withTintColor(.circularButtonNormal, renderingMode: .alwaysOriginal),
            for: .normal
        )
        $0.addTarget(self, action: #selector(setMicMode), for: .touchUpInside)
    }

    private lazy var mainButtonsStackView = UIStackView(arrangedSubviews: [cameraSwitchButton, recordButton, micModeButton]).configure {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
        $0.distribution = .equalCentering
        $0.alignment = .center
        $0.spacing = 38
    }

    private lazy var cancelButton = UIButton(type: .system).configure {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setTitle("Cancel", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 18, weight: .regular)
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOffset = CGSize(width: -0.5, height: 0.5)
        $0.layer.shadowOpacity = 0.8
        $0.layer.shadowRadius = 3
        $0.layer.masksToBounds = false
        $0.addTarget(self, action: #selector(cancel), for: .touchUpInside)
    }

    // other buttons

    private lazy var zoomButton = UIButton.circularButton().configure {
        func attributedText(prefix: String) -> NSAttributedString {
            let color: UIColor = prefix == "1" ? .circularButtonNormal : .circularButtonSelected
            let attachment = NSTextAttachment()
            let config = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
            attachment.image = UIImage(systemName: "xmark", withConfiguration: config)?
                .withTintColor(color)
                .imageWithoutBaseline() // or: .withBaselineOffset(fromBottom: UIFont.systemFontSize / 2)
            let textString = NSMutableAttributedString(string: prefix, attributes: [.foregroundColor: color])
            let imageString = NSAttributedString(attachment: attachment)
            textString.append(imageString)
            return textString
        }
        $0.titleLabel?.font = .preferredFont(forTextStyle: .headline) // move this to attributed text
        $0.setAttributedTitle(attributedText(prefix: "1"), for: .normal)
        $0.setAttributedTitle(attributedText(prefix: "2"), for: .selected)
//        $0.addTarget(self, action: #selector(zoomToggle), for: .touchUpInside)
    }

    private lazy var torchButton = UIButton.circularButton().configure {
        $0.setImage(
            UIImage(systemName: .symbolFlashOff, withConfiguration: .circularButton)?
                .withTintColor(.circularButtonNormal, renderingMode: .alwaysOriginal),
            for: .normal
        )
        $0.setImage(
            UIImage(systemName: .symbolFlashOn, withConfiguration: .circularButton)?
                .withTintColor(.circularButtonDisabled, renderingMode: .alwaysOriginal),
            for: .selected
        )
    }

    // center this
    private lazy var resumeButton = UIButton(type: .system).configure {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setTitle("Resume", for: .normal)
        $0.addTarget(self, action: #selector(resumeInterruptedSession), for: .touchUpInside)
    }

    // count up/down

    private lazy var countUpLabel = ColorLabelView(forAutoLayout: true).configure {
        $0.setup(
            text: "00:00",
            textColor: .white,
            font: .monospacedDigitSystemFont(ofSize: 24, weight: .medium),
            backgroundColor: .gray,
            cornerRadius: 3,
            inset: .smallTop
        )
        $0.backgroundColor = .circularButtonBackground
        $0.layer.cornerRadius = 3
        $0.layer.masksToBounds = true
    }

    private lazy var totalTimeLabel = UILabel(forAutoLayout: true).configure {
        $0.text = "05:00"
        $0.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        $0.textColor = .white
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOffset = CGSize(width: -0.5, height: 0.5)
        $0.layer.shadowOpacity = 0.8
        $0.layer.shadowRadius = 2
        $0.layer.masksToBounds = false
    }

    // MARK: - Properties

    private var cameraController: CameraController!

    // MARK: - View Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        if #available(iOS 15.0, *) {
            AVCaptureDevice.self.addObserver(self, forKeyPath: .activeMicrophoneMode, options: [.initial, .new], context: nil)
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if cameraController == nil {
            setUpCamera()
        }
        cameraController.startSession()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        cameraController.stopSession()
        super.viewWillDisappear(animated)
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }

    override public var shouldAutorotate: Bool {
        cameraController.shouldAutorotate
    }

    // https://developer.apple.com/forums/thread/691850
    // https://stackoverflow.com/questions/49747536/xcode-9-block-based-kvo-violation-for-observevalue-function
    // https://github.com/realm/SwiftLint/issues/1989
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == .activeMicrophoneMode {
            guard let object = object as? AVCaptureDevice.Type else { return }
            DispatchQueue.main.async { [weak self] in
                if #available(iOS 15.0, *) {
                    self?.updateMicModeButton(object.activeMicrophoneMode)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    // MARK: - CameraControllerDelegate

    var windowOrientation: UIInterfaceOrientation {
        view.window?.windowScene?.interfaceOrientation ?? .unknown
    }

    func recordingEnabled(_ enabled: Bool) {
        recordButton.isEnabled = enabled
    }

    func isRecording(_ isRecording: Bool) {
        recordButton.isSelected = isRecording
        cameraSwitchButton.isHidden = isRecording
        micModeButton.isHidden = isRecording
        torchButton.isHidden = isRecording
    }

    func cameraSwitchingEnabled(_ enabled: Bool) {
        cameraSwitchButton.isEnabled = enabled
    }

    func micModeEnabled(_ enabled: Bool) {
        micModeButton.isEnabled = enabled
    }

    func resumingEnabled(_ enabled: Bool) {
        resumeButton.isHidden = !enabled
    }

    func resumeFailed() {
        let message = NSLocalizedString("Unable to resume", comment: "Alert message when unable to resume the session running")
        let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }

    func newVideoFile(_ path: String) {
        guard UIVideoEditorController.canEditVideo(atPath: path) else { return }

        // On iPad, UIVideoEditorController must be presented as a popover, so make the biggest popover we can.
        let containerVC = UIViewController()
        containerVC.preferredContentSize = UIScreen.main.bounds.size
        containerVC.modalPresentationStyle = .popover
        containerVC.isModalInPresentation = true

        let ppc = containerVC.popoverPresentationController
        ppc?.sourceView = containerVC.view
        ppc?.sourceRect = UIScreen.main.bounds
        ppc?.permittedArrowDirections = .init(rawValue: 0 )
        ppc?.canOverlapSourceViewRect = true

        let editor = UIVideoEditorController()
        editor.delegate = self
        editor.videoPath = path
        editor.videoQuality = .typeHigh
        // editor.videoMaximumDuration = 10 (in seconds. set to Redzone max video length)

        containerVC.addChild(editor)
        containerVC.view.addSubview(editor.view)
        editor.didMove(toParent: containerVC)

        self.present(containerVC, animated: true)
    }

    // MARK: - UIVideoEditorControllerDelegate

    public func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        editor.delegate = nil
        dismiss(animated: true) {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges({
                        let options = PHAssetResourceCreationOptions()
                        options.shouldMoveFile = true
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .video, fileURL: URL(string: editedVideoPath)!, options: options)
                    }, completionHandler: { success, error in
                        if !success {
                            print("Couldn't save the movie to your photo library: \(String(describing: error))")
                        }
                        DispatchQueue.main.async {
                            self.dismiss(animated: true)
                        }
                    })
                } else {
                    print("Photos not authorized")
                }
            }
        }

    }

    public func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
        dismiss(animated: true)
    }

    public func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
        print("an error occurred: \(error.localizedDescription)")
        dismiss(animated: true)
    }

    // MARK: - Actions

    @objc private func cancel(_ button: UIButton) {
        dismiss(animated: true)
    }

    @objc private func setMicMode(_ button: UIButton) {
        if #available(iOS 15.0, *) {
            AVCaptureDevice.showSystemUserInterface(.microphoneModes)
        }
    }

    @objc private func toggleRecording(_ recordButton: UIButton) {
        cameraController.toggleRecording()
    }

    @objc private func switchCamera(_ cameraButton: UIButton) {
        cameraController.switchCamera()
    }

    @objc private func resumeInterruptedSession(_ resumeButton: UIButton) {
        cameraController.resumeInterruptedSession()
    }

    @objc private func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let devicePoint = previewView.videoPreviewLayer.captureDevicePointConverted(
            fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view)
        )
        cameraController.focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
    }

    // MARK: - Methods

    private func setUpViews() {
        recordButton.isEnabled = false
        cameraSwitchButton.isEnabled = false
        resumeButton.isHidden = true
        isRecording(false)

        view.backgroundColor = .black

        // preview

        view.addSubview(previewView)
        NSLayoutConstraint.activate(previewView.constraints(for: .all, relativeTo: view))
        previewView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap))
        )

//        referenceImage.alpha = 0.1
//        view.addSubview(referenceImage)
//        NSLayoutConstraint.activate(referenceImage.constraints(for: .all, relativeTo: view))
        mainButtonsStackView.alpha = 1.0

        // main buttons

        view.addSubview(mainButtonsStackView)
        view.addSubview(cancelButton)
        view.addSubview(zoomButton)
        view.addSubview(torchButton)
        view.addSubview(countUpLabel)
        view.addSubview(totalTimeLabel)
        NSLayoutConstraint.activate([
            mainButtonsStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainButtonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainButtonsStackView.widthAnchor.constraint(equalToConstant: .mainButtonStackWidth),

            cancelButton.trailingAnchor.constraint(equalTo: mainButtonsStackView.trailingAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(equalToConstant: .mainButtonStackWidth),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),

            zoomButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            zoomButton.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor),

            torchButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            torchButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            countUpLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            countUpLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            totalTimeLabel.topAnchor.constraint(equalTo: countUpLabel.bottomAnchor, constant: 4),
            totalTimeLabel.centerXAnchor.constraint(equalTo: countUpLabel.centerXAnchor),
        ])

        // add resume button
    }

    private func setUpCamera() {
        cameraController = CameraController(previewView: previewView)
        previewView.session = cameraController.session
        cameraController.delegate = self
        cameraController.checkVideoAuthorization()
    }

    @available(iOS 15.0, *)
    private func updateMicModeButton(_ micMode: AVCaptureDevice.MicrophoneMode) {
        let symbol: String
        let tintColor: UIColor
        switch micMode {
        case .standard:
            symbol = .symbolMicStandard
            tintColor = .circularButtonNormal
        case .voiceIsolation:
            symbol = .symbolMicVoiceIsolation
            tintColor = .circularButtonSelected
        case .wideSpectrum:
            symbol = .symbolMicWideSpectrum
            tintColor = .circularButtonSelected
        @unknown default:
            fatalError()
        }
        micModeButton.setImage(
            UIImage(systemName: symbol, withConfiguration: .circularButton)?
                .withTintColor(tintColor, renderingMode: .alwaysOriginal),
            for: .normal
        )
    }
}
