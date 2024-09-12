import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!

    var chosenImage: CIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func changeClicked(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            imageView.image = selectedImage
            if let ciImage = CIImage(image: selectedImage) {
                chosenImage = ciImage
                recognizeImage(image: ciImage)
            }
        }
        dismiss(animated: true, completion: nil)
    }

    func recognizeImage(image: CIImage) {
        resultLabel.text = "Finding..."

        guard let model = try? VNCoreMLModel(for: MobileNetV2().model) else {
            print("Failed to load model")
            return
        }

        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                DispatchQueue.main.async {
                    self?.resultLabel.text = "No results"
                }
                return
            }

            DispatchQueue.main.async {
                let confidenceLevel = (topResult.confidence * 100).rounded()
                self?.resultLabel.text = String(format: "%.2f%% it's %@", confidenceLevel, topResult.identifier)
            }
        }

        let handler = VNImageRequestHandler(ciImage: image)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform image recognition: \(error.localizedDescription)")
            }
        }
    }
}
