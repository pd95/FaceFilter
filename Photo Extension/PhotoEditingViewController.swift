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

class PhotoEditingViewController: UIViewController, PHContentEditingController {

    enum ProcessingState: CustomStringConvertible {
        case initial, loading, detectingFaces, applyingDefaultFilters, editing, composingResultImage, done
        
        var description: String {
            switch self {
                case .initial:
                    return "Initial"
                case .loading:
                    return "Loading"
                case .detectingFaces:
                    return "Detecting Faces"
                case .applyingDefaultFilters:
                    return "Applying default filters"
                case .editing:
                    return "Editing"
                case .composingResultImage:
                    return "Composing result image"
                case .done:
                    return "Done"
            }
        }
    }
    
    var input: PHContentEditingInput?
    @IBOutlet weak var processingStateLabel: UILabel!
    
    var state : ProcessingState = .initial {
        didSet {
            processingStateLabel.text = "\(state)..."
            if state == .editing {
                // Animate label to invisibility
                if !self.processingStateLabel.isHidden {
                    UIView.animate(withDuration: 1, animations: {
                        self.processingStateLabel.alpha = 0
                    }, completion: { _ in
                        self.processingStateLabel.alpha = 1
                        self.processingStateLabel.isHidden = true
                    })
                }
            }
            else {
                // Animate label back to visibility
                if self.processingStateLabel.isHidden {
                    self.processingStateLabel.isHidden = false
                    UIView.animate(withDuration: 0.3, animations: {
                        self.processingStateLabel.alpha = 1
                    })
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        state = .loading
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.state = .detectingFaces
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.state = .applyingDefaultFilters
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.state = .editing
                }
            }
        }
    }
    
    func finishContentEditing(completionHandler: @escaping ((PHContentEditingOutput?) -> Void)) {
        // Update UI to reflect that editing has finished and output is being rendered.
        state = .composingResultImage

        // Render and provide output on a background queue.
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            // Create editing output from the editing input.
            let output = PHContentEditingOutput(contentEditingInput: self.input!)
            
            // Provide new adjustments and render output to given location.
            // output.adjustmentData = <#new adjustment data#>
            // let renderedJPEGData = <#output JPEG#>
            // renderedJPEGData.writeToURL(output.renderedContentURL, atomically: true)
            
            // Call completion handler to commit edit to Photos.
            completionHandler(output)
            
            // Clean up temporary files, etc.
            self.state = .done
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
    }

}
