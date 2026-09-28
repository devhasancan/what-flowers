import Foundation
import Vision
import CoreImage

final class FlowerViewModel {
    
    private(set) var state: FlowerState = .empty {
        didSet {
            let newState = state
            DispatchQueue.main.async { [weak self] in
                self?.onStateChange?(newState)
            }
        }
    }
    
    var onStateChange: ((FlowerState) -> Void)?
    
    private var recognizedName: String?
    private var flowerManager = FlowerManager()
    
    init() {
        flowerManager.delegate = self
    }
    
    func analyze(_ image: CIImage) {
        recognizedName = nil
        state = .loading
        detect(image)
    }
    
    private func detect(_ image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            state = .failure(message: "The recognition model could not be loaded.")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print(error)
                self.state = .failure(message: "The image could not be processed.")
                return
            }
            
            guard let classification = request.results?.first as? VNClassificationObservation else {
                self.state = .failure(message: "The flower could not be recognized. Try another photo.")
                return
            }
            
            self.recognizedName = classification.identifier
            self.flowerManager.fetchFlower(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try handler.perform([request])
            } catch {
                print(error)
                self?.state = .failure(message: "The image could not be processed.")
            }
        }
    }
}

extension FlowerViewModel: FlowerManagerDelegate {
    
    func didUpdateFlower(_ title: String, _ extract: String?, _ imageURL: String?) {
        let commonName = recognizedName ?? title
        let scientificName = commonName.lowercased() == title.lowercased() ? nil : title
        let description = extract ?? "No description was found on Wikipedia for this type."
        
        state = .success(FlowerPresentation(
            commonName: commonName,
            scientificName: scientificName,
            description: description,
            imageURL: imageURL
        ))
    }
    
    func didFailWithError(_ message: String) {
        state = .failure(message: message)
    }
    
}
