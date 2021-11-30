import AVFoundation
import Photos
import SwiftUI
import UIKit

private extension String {
    static let symbolCameraSwitch = "arrow.triangle.2.circlepath.camera"
    static let symbolRecord = "record.circle"
    static let symbolStop = "stop.circle"
    static let symbolMicStandard = "mic.fill"
    static let symbolMicVoiceIsolation = "person.wave.2.fill"
    static let symbolMicWideSpectrum = "waveform.and.mic"
    static let activeMicrophoneMode = "activeMicrophoneMode"
}

private extension UIColor {
    static let buttonNormal = UIColor.white
    static let buttonDisabled = UIColor.gray
    static let buttonRecord = UIColor.red
}

private extension CGColor {
    static let shadow = UIColor.black.cgColor
}

private extension UIImage.Configuration {
    static let buttonNormal = UIImage.SymbolConfiguration(pointSize: 25, weight: .regular)
    static let buttonRecord = UIImage.SymbolConfiguration(pointSize: 70, weight: .regular)
}

final class RedzoneCameraViewController: UIViewController, CameraControllerDelegate, UIVideoEditorControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Views

    private lazy var previewView = PreviewView(forAutoLayout: true)

    private lazy var referenceImage = UIImageView(forAutoLayout: true).configure {
        $0.image = UIImage(named: "IMG_0136")
    }

    // main buttons

    private lazy var mainButtonsContainer = UIView(forAutoLayout: true)

    private lazy var cameraSwitchButton = UIButton(forAutoLayout: true).configure {
        $0.setImage(
            UIImage(systemName: .symbolCameraSwitch, withConfiguration: .buttonNormal)?
                .withTintColor(.buttonNormal, renderingMode: .alwaysOriginal),
            for: .normal
        )
        $0.setImage(
            UIImage(systemName: .symbolCameraSwitch, withConfiguration: .buttonNormal)?
                .withTintColor(.buttonDisabled, renderingMode: .alwaysOriginal),
            for: .disabled
        )
        $0.layer.shadowColor = .shadow
        $0.layer.shadowOffset = CGSize(width: -0.5, height: 0.5)
        $0.layer.shadowOpacity = 0.7
        $0.layer.shadowRadius = 5
        $0.layer.masksToBounds = false
        $0.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
    }

    private lazy var recordButton = UIButton(forAutoLayout: true).configure {
        $0.setImage(
            UIImage(systemName: .symbolRecord, withConfiguration: .buttonRecord)?
                .withTintColor(.buttonRecord, renderingMode: .alwaysOriginal),
            for: .normal
        )
        $0.setImage(
            UIImage(systemName: .symbolStop, withConfiguration: .buttonRecord)?
                .withTintColor(.buttonNormal, renderingMode: .alwaysOriginal),
            for: .selected
        )
        $0.setImage(
            UIImage(systemName: .symbolRecord, withConfiguration: .buttonRecord)?
                .withTintColor(.buttonDisabled, renderingMode: .alwaysOriginal),
            for: .disabled
        )
        $0.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
    }

    private lazy var cancelButton = UIButton(forAutoLayout: true).configure {
        $0.setTitle("Cancel", for: .normal)
        $0.layer.shadowColor = .shadow
        $0.layer.shadowOffset = CGSize(width: -0.5, height: 0.5)
        $0.layer.shadowOpacity = 0.5
        $0.layer.shadowRadius = 2
        $0.layer.masksToBounds = false
        $0.addTarget(self, action: #selector(cancel), for: .touchUpInside)
    }

    // secondary buttons

    private lazy var secondaryButtonsContainer = UIView(forAutoLayout: true)

    private lazy var micModeButton = UIButton(forAutoLayout: true).configure {
        $0.setImage(
            UIImage(systemName: .symbolMicStandard, withConfiguration: .buttonNormal)?
                .withTintColor(.buttonNormal, renderingMode: .alwaysOriginal),
            for: .normal
        )
        $0.layer.shadowColor = .shadow
        $0.layer.shadowOffset = CGSize(width: -0.5, height: 0.5)
        $0.layer.shadowOpacity = 0.5
        $0.layer.shadowRadius = 2
        $0.layer.masksToBounds = false
        $0.addTarget(self, action: #selector(setMicMode), for: .touchUpInside)
    }
    private lazy var resumeButton = UIButton(forAutoLayout: true).configure {
        $0.setTitle("Resume", for: .normal)
        $0.addTarget(self, action: #selector(resumeInterruptedSession), for: .touchUpInside)
    }

    // MARK: - Properties

    private lazy var cameraController = CameraController(previewView: previewView)

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpCamera()
        AVCaptureDevice.self.addObserver(self, forKeyPath: .activeMicrophoneMode, options: [.initial, .new], context: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraController.startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        cameraController.stopSession()
        super.viewWillDisappear(animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
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

    override var shouldAutorotate: Bool {
        cameraController.shouldAutorotate
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == .activeMicrophoneMode {
            guard let object = object as? AVCaptureDevice.Type else { return }
            DispatchQueue.main.async { [weak self] in
                self?.updateMicModeButton(object.activeMicrophoneMode)
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
    }

    func cameraSwitchingEnabled(_ enabled: Bool) {
        cameraSwitchButton.isEnabled = enabled
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
        //editor.videoMaximumDuration = 10 (in seconds. set to Redzone max video length)

        containerVC.addChild(editor)
        containerVC.view.addSubview(editor.view)
        editor.didMove(toParent: containerVC)

        self.present(containerVC, animated: true)
    }

    // MARK: - UIVideoEditorControllerDelegate

    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
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
                        self.dismiss(animated:true)
                    }
                })
            } else {
                print("Photos not authorized")
            }
        }

    }

    func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
        dismiss(animated:true)
    }

    func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
        print("an error occurred: \(error.localizedDescription)")
        dismiss(animated:true)
    }

    // MARK: - Actions

    @objc private func cancel(_ button: UIButton) {
        dismiss(animated: true)
    }

    @objc private func setMicMode(_ button: UIButton) {
        AVCaptureDevice.showSystemUserInterface(.microphoneModes)
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

        // main buttons

        view.addSubview(mainButtonsContainer)
        NSLayoutConstraint.activate {
            $0 += mainButtonsContainer.constraints(for: [.top, .bottom, .trailing], relativeTo: view)
            $0 += mainButtonsContainer.constraints(for: Size(width: 106, height: .none))
        }
        mainButtonsContainer.addSubview(cameraSwitchButton)
        mainButtonsContainer.addSubview(recordButton)
        mainButtonsContainer.addSubview(cancelButton)
        NSLayoutConstraint.activate([
            cameraSwitchButton.leadingAnchor.constraint(equalTo: mainButtonsContainer.leadingAnchor),
            cameraSwitchButton.trailingAnchor.constraint(equalTo: mainButtonsContainer.trailingAnchor),
            cameraSwitchButton.bottomAnchor.constraint(equalTo: recordButton.topAnchor, constant: 0),
            cameraSwitchButton.heightAnchor.constraint(equalTo: cameraSwitchButton.widthAnchor),

            recordButton.leadingAnchor.constraint(equalTo: mainButtonsContainer.leadingAnchor),
            recordButton.trailingAnchor.constraint(equalTo: mainButtonsContainer.trailingAnchor),
            recordButton.centerYAnchor.constraint(equalTo: mainButtonsContainer.centerYAnchor),
            recordButton.heightAnchor.constraint(equalTo: recordButton.widthAnchor),

            cancelButton.leadingAnchor.constraint(equalTo: mainButtonsContainer.leadingAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: mainButtonsContainer.trailingAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: mainButtonsContainer.bottomAnchor, constant: -30)
        ])

        // secondary buttons

        view.addSubview(secondaryButtonsContainer)
        NSLayoutConstraint.activate {
            $0 += secondaryButtonsContainer.constraints(for: [.leading, .top, .bottom], relativeTo: view)
            $0 += secondaryButtonsContainer.constraints(for: Size(width: 80, height: .none))
        }
        secondaryButtonsContainer.addSubview(micModeButton)
        NSLayoutConstraint.activate([
            micModeButton.leadingAnchor.constraint(equalTo: secondaryButtonsContainer.leadingAnchor),
            micModeButton.trailingAnchor.constraint(equalTo: secondaryButtonsContainer.trailingAnchor),
            micModeButton.centerYAnchor.constraint(equalTo: secondaryButtonsContainer.centerYAnchor),
            micModeButton.heightAnchor.constraint(equalTo: micModeButton.widthAnchor)
        ])
    }

    private func setUpCamera() {
        previewView.session = cameraController.session
        cameraController.delegate = self
        cameraController.checkVideoAuthorization()
    }

    private func updateMicModeButton(_ micMode: AVCaptureDevice.MicrophoneMode) {
        let symbol: String
        switch micMode {
        case .standard:
            symbol = .symbolMicStandard
        case .voiceIsolation:
            symbol = .symbolMicVoiceIsolation
        case .wideSpectrum:
            symbol = .symbolMicWideSpectrum
        @unknown default:
            fatalError()
        }
        micModeButton.setImage(
            UIImage(systemName: symbol, withConfiguration: .buttonNormal)?
                .withTintColor(.buttonNormal, renderingMode: .alwaysOriginal),
            for: .normal
        )
    }
}

//extension RedzoneCameraViewController: UIViewControllerRepresentable {
//  func makeUIViewController(context: Context) -> ViewController {
//      return ViewController()
//  }
//
//  func updateUIViewController(_ uiViewController: ViewController,
//    context: Context) {
//  }
//}
//
//struct ViewControllerPreviews: PreviewProvider {
//    static var previews: some View {
//        ViewController()
//            .ignoresSafeArea()
//            .previewDevice("iPad (9th generation)")
//            .previewInterfaceOrientation(.landscapeLeft)
//    }
//}
