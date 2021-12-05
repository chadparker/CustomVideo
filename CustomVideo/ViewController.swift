import SwiftUI
import UIKit

final class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let button = UIButton(forAutoLayout: true).configure {
            $0.setTitle("Present Video Camera", for: .normal)
            $0.setTitleColor(.link, for: .normal)
            $0.addTarget(self, action: #selector(showCamera), for: .touchUpInside)
        }

        view.addSubview(button)
        NSLayoutConstraint.activate(button.constraints(for: .all, relativeTo: view))
    }

    @objc func showCamera(_ button: UIButton) {
//        let cameraVC = ButtonsPreviewVC()
        let cameraVC = RedzoneCameraViewController()
        cameraVC.modalPresentationStyle = .fullScreen
        present(cameraVC, animated: true) {

        }
    }
}

extension ViewController: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> ViewController {
      return ViewController()
  }

  func updateUIViewController(_ uiViewController: ViewController,
    context: Context) {
  }
}
struct ViewControllerPreviews: PreviewProvider {
    static var previews: some View {
        ViewController()
            .ignoresSafeArea()
            .previewDevice("iPad (9th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
