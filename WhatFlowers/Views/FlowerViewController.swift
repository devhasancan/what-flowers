import UIKit
import CoreML
import Vision

class FlowerViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let imagePicker = UIImagePickerController()
    private let viewModel = FlowerViewModel()
    private var pendingImageURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        imagePicker.allowsEditing = true
        
        let apperance = UINavigationBarAppearance()
        apperance.configureWithOpaqueBackground()
        apperance.backgroundColor = .flowerAccent
        apperance.titleTextAttributes = [.foregroundColor: UIColor.white,
                                         .font: UIFont.systemFont(ofSize: 20, weight: .bold)]
        navigationController?.navigationBar.standardAppearance = apperance
        navigationController?.navigationBar.scrollEdgeAppearance = apperance
        navigationItem.rightBarButtonItem?.tintColor = .white
        
        title = "WhatFlowers"
        
        setupPhotoButton()
        setupAppearance()
        
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        render(viewModel.state)
    }
    
    private func setupPhotoButton() {
        imageView.isUserInteractionEnabled = true
        
        let photoButton = UIButton(type: .system)
        photoButton.backgroundColor = .clear
        photoButton.accessibilityLabel = "Select a photo"
        photoButton.translatesAutoresizingMaskIntoConstraints = false
        
        photoButton.addAction(UIAction { [weak self] _ in
            self?.presentImagePicker()
        }, for: .touchUpInside)
        
        imageView.addSubview(photoButton)
        
        NSLayoutConstraint.activate([
            photoButton.topAnchor.constraint(equalTo: imageView.topAnchor),
            photoButton.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            photoButton.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            photoButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        ])
    }
    
    private func setupAppearance() {
        view.backgroundColor = .flowerBackground
        
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        
        descriptionTextView.backgroundColor = .white
        descriptionTextView.layer.cornerRadius = 16
        descriptionTextView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        descriptionTextView.textAlignment = .left
        descriptionTextView.textColor = .flowerInk
        descriptionTextView.font = .systemFont(ofSize: 17)
        
        descriptionTextView.clipsToBounds = true
        descriptionTextView.layer.borderWidth = 1
        descriptionTextView.layer.borderColor = UIColor(white: 0, alpha: 0.06).cgColor
        
        activityIndicator.color = .flowerAccent
    }
    
    private func showEmptyState() {
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "camera.viewfinder")
        imageView.tintColor = UIColor.flowerAccent.withAlphaComponent(0.36)
        descriptionTextView.text = "Tap the photo above or the camera button in the top right to get started."
        descriptionTextView.textColor = .flowerInkSoft
    }
    
    private func render(_ state: FlowerState) {
        switch state {
        case .empty:
            activityIndicator.stopAnimating()
            showEmptyState()
            
        case .loading:
            pendingImageURL = nil
            descriptionTextView.text = "Recognising the flower..."
            descriptionTextView.textColor = .flowerInkSoft
            activityIndicator.startAnimating()
            
        case .success(let presentation):
            activityIndicator.stopAnimating()
            show(presentation)
            
        case .failure(let message):
            activityIndicator.stopAnimating()
            descriptionTextView.text = message
            descriptionTextView.textColor = .flowerInkSoft
        }
    }
    
    private func show(_ presentation: FlowerPresentation) {
        let text = NSMutableAttributedString(
            string: presentation.commonName + "\n",
            attributes: [.font: UIFont.systemFont(ofSize: 28, weight: .bold),
                         .foregroundColor: UIColor.flowerInk]
        )
        
        if let scientificName = presentation.scientificName {
            text.append(NSAttributedString(
                string: "Scientific name: " + scientificName + "\n\n",
                attributes: [.font: UIFont.italicSystemFont(ofSize: 15),
                             .foregroundColor: UIColor.flowerInkSoft]
            ))
        } else {
            text.append(NSAttributedString(
                string: "\n",
                attributes: [.font: UIFont.italicSystemFont(ofSize: 15)]
            ))
        }
        
        text.append(NSAttributedString(
            string: presentation.description,
            attributes: [.font: UIFont.systemFont(ofSize: 17),
                         .foregroundColor: UIColor.flowerInk]
        ))
        
        descriptionTextView.attributedText = text
        descriptionTextView.setContentOffset(.zero, animated: false)
        
        loadImage(from: presentation.imageURL)
    }
    
    private func loadImage(from urlString: String?) {
        guard let urlString = urlString,
              let url = URL(string: urlString) else { return }
        
        pendingImageURL = url
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            guard let data = data, let image = UIImage(data: data) else {
                print(error ?? "Image could not be decoded.")
                return
            }
            
            DispatchQueue.main.async {
                guard self.pendingImageURL == url else { return }
                self.imageView.contentMode = .scaleAspectFill
                self.imageView.image = image
            }
        }
        .resume()
    }
        
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            imageView.contentMode = .scaleAspectFill
            imageView.image = userPickedImage
            
            descriptionTextView.text = "Recognising the flower..."
            descriptionTextView.textColor = .flowerInkSoft
            
            guard let convertedCIImage = CIImage(image: userPickedImage) else {fatalError("Can not convert to CIImage")}
            activityIndicator.startAnimating()
            viewModel.analyze(convertedCIImage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
        
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func presentImagePicker() {
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    
    

}

//MARK: - UIImagePickerControllerDelegate

extension FlowerViewController: UIImagePickerControllerDelegate {
}

//MARK: - UINavigationControllerDelegate

extension FlowerViewController: UINavigationControllerDelegate {
}
