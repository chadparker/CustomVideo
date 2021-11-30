import AVFoundation
import Photos
import SwiftUI
import UIKit

class ViewController: UIViewController, CameraControllerDelegate, UIVideoEditorControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Views

    private lazy var micModeButton = UIButton(type: .roundedRect).configure {
        $0.setTitle("Mic Mode", for: .normal)
        $0.addTarget(self, action: #selector(setMicMode), for: .touchUpInside)
    }
    private lazy var recordButton = UIButton(type: .roundedRect).configure {
        $0.setTitle("Record", for: .normal)
        $0.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
    }
    private lazy var cameraSwitchButton = UIButton(type: .roundedRect).configure {
        $0.setTitle("Switch Camera", for: .normal)
        $0.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
    }
    private lazy var resumeButton = UIButton(type: .roundedRect).configure {
        $0.setTitle("Resume", for: .normal)
        $0.addTarget(self, action: #selector(resumeInterruptedSession), for: .touchUpInside)
    }

    private lazy var buttonStackView = UIStackView(
        arrangedSubviews: [resumeButton, recordButton, micModeButton, cameraSwitchButton]
    ).configure {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private lazy var previewView = PreviewView().configure {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    private lazy var spinner = UIActivityIndicatorView(style: .large).configure {
        $0.color = UIColor.yellow
    }

    // MARK: - Properties

    private lazy var cameraController = CameraController(previewView: previewView)

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpCamera()
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

    // MARK: - CameraControllerDelegate

    var windowOrientation: UIInterfaceOrientation {
        view.window?.windowScene?.interfaceOrientation ?? .unknown
    }

    func recordingEnabled(_ enabled: Bool) {
        recordButton.isEnabled = enabled
    }

    func isRecording(_ isRecording: Bool) {
        recordButton.setTitle(
            isRecording ? "Stop" : "Record",
            for: .normal
        )
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
        editor.videoMaximumDuration = 10

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

        view.addSubview(previewView)
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        view.addSubview(buttonStackView)
        NSLayoutConstraint.activate([
            buttonStackView.heightAnchor.constraint(equalToConstant: 150),
            buttonStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        previewView.addSubview(self.spinner)

        view.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap))
        )
    }

    private func setUpCamera() {
        previewView.session = cameraController.session
        cameraController.delegate = self
        cameraController.checkVideoAuthorization()
    }
}

//extension ViewController: UIViewControllerRepresentable {
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
