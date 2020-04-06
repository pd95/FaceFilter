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

    private let model = AppModel.shared
    private var pickingImage = false

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
            // register us as PresentationController delegate to ensure we get notifed on modal dismissal
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
    
    // Displays the given image in the UIImageView and adjusts the UIScrollView
    func showImage(_ image: UIImage?) {
        imageView.image = image
        if let image = image {
            let svHeight = scrollView.bounds.size.height
            let imHeight = image.size.height
            let scale = svHeight / imHeight
            scrollView.zoomScale = scale
            scrollView.contentOffset = .zero
        }
    }


    // Processes the given image in the background, applies the filter and displays the result
    func processImage(_ image: UIImage) {
        showImage(image)
        DispatchQueue.global(qos: .background).async {

            // The first steps are only needed once
            self.model.detectFaces(in: image)

            // The bluring of the image has to be reapplied whenever the parameters change
            self.model.calculateMask()
            self.model.blurHeads()

            DispatchQueue.main.async {
                let ciImage = self.model.outputImage!
                self.showImage(UIImage(ciImage: ciImage))
            }
        }
    }

    // Updates the current image in the background, applying the filter and displaying the result
    func refreshImage() {
        DispatchQueue.global(qos: .background).async {
            // The bluring of the image has to be reapplied whenever the parameters change
            self.model.calculateMask()
            self.model.blurHeads()
            DispatchQueue.main.async {
                self.imageView.image = UIImage(ciImage: self.model.outputImage!)
            }
        }
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
    }
}

