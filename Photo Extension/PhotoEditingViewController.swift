//
//  PhotoEditingViewController.swift
//  Photo Extension
//
//  Created by Philipp on 07.04.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class PhotoEditingViewController: UIViewController, PHContentEditingController, UIScrollViewDelegate {

    @IBOutlet weak var imageView: UIImageView!
    var pixellator: FacePixellator!
    var input: PHContentEditingInput?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        UIBarButtonItem.appearance().tintColor = .systemYellow

        UINavigationBar.appearance().tintColor = .systemYellow
        UINavigationBar.appearance().barTintColor = .systemYellow
        UINavigationBar.appearance().backgroundColor = .red

        navigationController?.navigationBar.tintColor = .systemYellow
        navigationController?.navigationBar.barTintColor = .systemYellow
    }
        
    // MARK: - PHContentEditingController
    
    func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        // Inspect the adjustmentData to determine whether your extension can work with past edits.
        // (Typically, you use its formatIdentifier and formatVersion properties to do this.)
        return false
    }
    
    func startContentEditing(with contentEditingInput: PHContentEditingInput, placeholderImage: UIImage) {
        // Present content for editing, and keep the contentEditingInput for use when closing the edit session.
        // If you returned true from canHandleAdjustmentData:, contentEditingInput has the original image and adjustment data.
        // If you returned false, the contentEditingInput has past edits "baked in".
        input = contentEditingInput

        let displayImage = contentEditingInput.displaySizeImage!
        imageView.image = displayImage
        
        pixellator = FacePixellator()
        pixellator.set(uiImage: displayImage)
        pixellator.detectFaces()
        
        let resultImage = pixellator.resultImage()

        self.imageView.image = UIImage(ciImage: resultImage)
    }
    
    func finishContentEditing(completionHandler: @escaping ((PHContentEditingOutput?) -> Void)) {
        // Update UI to reflect that editing has finished and output is being rendered.

        // Render and provide output on a background queue.
        DispatchQueue.global(qos: .userInitiated).async {
            
            self.pixellator.set(imageFromUrl: self.input!.fullSizeImageURL!)

            // Create editing output from the editing input.
            let output = PHContentEditingOutput(contentEditingInput: self.input!)
            
            // Provide new adjustments and render output to given location.
            if let archivedData = try? NSKeyedArchiver.archivedData(withRootObject: "CIPixellate", requiringSecureCoding: false) {

                let adjustmentData = PHAdjustmentData(
                    formatIdentifier: "com.yourcompany.face-filter",
                    formatVersion: "1.0",
                    data: archivedData)

                output.adjustmentData = adjustmentData
            }

            let resultImage = self.pixellator.resultImage()
            do {
                let resultUIImage = UIImage(ciImage: resultImage)
                let renderedJPEGData = resultUIImage.jpegData(compressionQuality: 0.8)!
                try renderedJPEGData.write(to: output.renderedContentURL, options: [.atomic])
            } catch {
                print("Error writing JPEG: \(error)")
            }
    
            // Call completion handler to commit edit to Photos.
            completionHandler(output)
            
            // Clean up temporary files, etc.
            self.pixellator = nil
        }
    }
    
    var shouldShowCancelConfirmation: Bool {
        // Determines whether a confirmation to discard changes should be shown to the user on cancel.
        // (Typically, this should be "true" if there are any unsaved changes.)
        return false
    }
    
    func cancelContentEditing() {
        // Clean up temporary files, etc.
        // May be called after finishContentEditingWithCompletionHandler: while you prepare output.
        self.pixellator = nil
    }

    // MARK: - Scroll View Delegate protocol
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}


