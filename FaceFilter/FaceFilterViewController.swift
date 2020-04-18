//
//  FaceFilterViewController.swift
//  FaceFilter
//
//  Created by Philipp on 20.03.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import UIKit
import CoreImage.CIFilterBuiltins
import Vision

class FaceFilterViewController: UIViewController {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var filterOptionsButton: UIBarButtonItem!
    @IBOutlet weak var overviewSwitch: UISwitch!

    private let model = AppModel.shared
    private var pickingImage = false

    private var showOverview = false {
        didSet {
            overviewSwitch.isOn = showOverview
            if oldValue != showOverview {
                refreshImage(resetScrollView: true, fitToWidth: showOverview)
            }
        }
    }
    
    private lazy var picker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        return picker
    }()

    
    // MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !pickingImage {
            chooseImage()
        }
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "showFilterControl" {
            // register us as PresentationController delegate to ensure we get notified on modal dismissal
            let navigationController = segue.destination as! UINavigationController
            if #available(iOS 13.0, *) {
                // Modal Dismiss iOS 13
                navigationController.topViewController?.presentationController?.delegate = self
            } else {
                // Fallback on earlier versions
                // ??
            }
            navigationController.presentationController?.delegate = self
        }
    }


    // MARK: - View controller main functionality
    func resetScrollView(for image: UIImage, fitToWidth: Bool = false) {
        let svSize = scrollView.bounds.size
        let imSize = image.size
        let scale = fitToWidth ? svSize.width / imSize.width : svSize.height / imSize.height
        scrollView.zoomScale = scale
        scrollView.contentOffset = .zero
    }
    
    // Displays the given image in the UIImageView and adjusts the UIScrollView
    func showImage(_ image: UIImage?) {
        imageView.contentMode = .center
        imageView.image = image
        let hasFaces = model.numberOfFaces > 0
        shareButton.isEnabled = hasFaces
        filterOptionsButton.isEnabled = hasFaces
        overviewSwitch.isEnabled = hasFaces
    }


    // Processes the given image in the background, applies the filter and displays the result
    func processImage(_ image: UIImage) {
        self.showOverview = false
        showImage(image)
        self.resetScrollView(for: image)
        DispatchQueue.global(qos: .background).async {

            // The first steps are only needed once
            self.model.detectFaces(in: image)

            let resultImage = self.model.resultImage()
            DispatchQueue.main.async {
                self.showImage(resultImage)
            }
        }
    }

    // Updates the current image in the background, applying the filter and displaying the result
    func refreshImage(resetScrollView: Bool = false, fitToWidth: Bool = false) {
        guard !pickingImage else { return }

        DispatchQueue.global(qos: .background).async {
            
            let resultImage = self.showOverview ? self.model.overviewImage() :  self.model.resultImage()
            DispatchQueue.main.async {
                self.showImage(resultImage)
                if resetScrollView {
                    self.resetScrollView(for: resultImage, fitToWidth: fitToWidth)
                }
            }
        }
    }

    @IBAction func toggleOverview(_ sender: UISwitch) {
        showOverview = sender.isOn
    }
    
    // Action used to trigger the display of the Image Picker
    @IBAction func chooseImage() {
        pickingImage = true
        picker.sourceType = .photoLibrary
        self.present(picker, animated: true, completion: nil)
    }

    // Action used to trigger the display of the Image Picker
    @IBAction func takePhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            pickingImage = true
            picker.sourceType = .camera
            self.present(picker, animated: true, completion: nil)
        }
        else {
            print("Sorry cant take picture")
        }
    }

    // Action used to trigger the display of the "share sheet"
    @IBAction func shareImage() {
        if let image = imageView.image {
            // Create a JPEG file
            let fileUrl = FileManager.default.temporaryDirectory.appendingPathComponent("filtered.jpeg")
            let jpegData = image.jpegData(compressionQuality: 0.8)!
            try? jpegData.write(to: fileUrl, options: [.atomicWrite])

            // Present activity sheet with generated file
            let items : [Any] = [fileUrl]
            let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
            self.present(activityVC, animated: true)
        }
    }

    @IBAction func longpressOccured(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {

            let view = sender.view!
            let absoluteLocation = sender.location(in: view)
            
            // Translate the absolute coordinates into relative (with swapped Y axis)
            let relativeLocation = absoluteLocation
                .applying(.init(scaleX: 1 / view.bounds.size.width, y: -1 / view.bounds.size.height))
                .applying(.init(translationX: 0.0, y: 1.0))
            if !showOverview {
                model.addFace(at: relativeLocation)
                refreshImage()
            }
        }
    }
}


// MARK: - Presentation Controller Delegate protocol
extension FaceFilterViewController: UIAdaptivePresentationControllerDelegate {

    // This method gets called when the modal view is dismissed
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        refreshImage()
    }
}


// MARK: - Scroll View Delegate protocol
extension FaceFilterViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}


// MARK: - Image Picker Controller Delegate protocol
extension FaceFilterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        showImage(nil)
        picker.dismiss(animated: true, completion: {
            var image = info[.editedImage] as? UIImage
            if image == nil {
                image = info[.originalImage] as? UIImage
            }
            if let image = image {
                self.processImage(image)
            }
            self.pickingImage = false
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        pickingImage = false
        picker.dismiss(animated: true, completion: nil)
    }
}

