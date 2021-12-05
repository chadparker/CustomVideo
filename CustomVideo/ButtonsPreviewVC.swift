import RedzoneUI
import SwiftUI

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
    //static let buttonRecord: UIColor = .red
}

private extension UIImage.Configuration {
    static let circularButton = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
}

private extension CGFloat {
    static let mainButtonStackWidth: CGFloat = 106
    static let circularButtonSize: CGFloat = 40
    //static let recordButtonSize: CGFloat = 76
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

final class ButtonsPreviewVC: UIViewController {

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
        //$0.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
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
        //$0.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
    }

    private lazy var micModeButton = UIButton.circularButton().configure {
        $0.setImage(
            UIImage(systemName: .symbolMicStandard, withConfiguration: .circularButton)?
                .withTintColor(.circularButtonNormal, renderingMode: .alwaysOriginal),
            for: .normal
        )
        //$0.addTarget(self, action: #selector(setMicMode), for: .touchUpInside)
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
        $0.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOffset = CGSize(width: -0.5, height: 0.5)
        $0.layer.shadowOpacity = 0.5
        $0.layer.shadowRadius = 2
        $0.layer.masksToBounds = false
        //$0.addTarget(self, action: #selector(cancel), for: .touchUpInside)
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
        //$0.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
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
        //$0.addTarget(self, action: #selector(resumeInterruptedSession), for: .touchUpInside)
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

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }

    private func setUpViews() {
//        recordButton.isEnabled = false
//        cameraSwitchButton.isEnabled = false
//        resumeButton.isHidden = true
//        isRecording(false)

        view.backgroundColor = .black

        // preview

//        view.addSubview(previewView)
//        NSLayoutConstraint.activate(previewView.constraints(for: .all, relativeTo: view))
//        previewView.addGestureRecognizer(
//            UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap))
//        )

        referenceImage.alpha = 0
        view.addSubview(referenceImage)
        NSLayoutConstraint.activate(referenceImage.constraints(for: .all, relativeTo: view))
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
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
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
}

extension ButtonsPreviewVC: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ButtonsPreviewVC {
        return ButtonsPreviewVC()
    }

  func updateUIViewController(_ uiViewController: ButtonsPreviewVC,
    context: Context) {
  }
}
struct ButtonsPreviewVCPreviews: PreviewProvider {
    static var previews: some View {
        ButtonsPreviewVC()
            .ignoresSafeArea()
            .previewDevice("iPad (9th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
