//
//  FilterControlViewController.swift
//  FaceFilter
//
//  Created by Philipp on 24.03.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import UIKit


class FilterControlViewController: UIViewController {

    @IBOutlet private weak var filterSegmentControl: UISegmentedControl!
    @IBOutlet private weak var inputScaleLabel: UILabel!
    @IBOutlet private weak var inputScale: UISlider!
    @IBOutlet private weak var overshootAmountLabel: UILabel!
    @IBOutlet private weak var overshootAmount: UISlider!
    @IBOutlet weak var facePreview: UIImageView!
    
    private let model = AppModel.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterSegmentControl.selectedSegmentIndex = model.currentFilterIndex
        filterSelected(filterSegmentControl)
    }
    
    @IBAction func scaleChanged(_ sender: UISlider) {
        inputScale.value = floor(inputScale.value)
        inputScaleLabel.text = "\(inputScale.value)"
        model.currentParameterValue = inputScale.value

        model.blurHeads()
        refreshPreview()
    }

    @IBAction func overshootAmountChanged(_ sender: UISlider) {
        overshootAmount.value = round(overshootAmount.value * 10) / 10
        overshootAmountLabel.text = "\(overshootAmount.value)"
        model.overshootAmount = CGFloat(overshootAmount.value)
        model.calculateMask()
        refreshPreview()
    }

    @IBAction func filterSelected(_ sender: UISegmentedControl) {
        model.currentFilterIndex = sender.selectedSegmentIndex
        inputScale.maximumValue = model.allowedFilter[model.currentFilterIndex].maximumValue
        inputScale.minimumValue = model.allowedFilter[model.currentFilterIndex].minimumValue
        inputScale.value = model.currentParameterValue
        inputScaleLabel.text = "\(inputScale.value)"
        overshootAmount.value = Float(model.overshootAmount)
        overshootAmountLabel.text = "\(overshootAmount.value)"
        
        model.blurHeads()
        refreshPreview()
    }
    
    func refreshPreview() {
        if let faceRect = model.detectedFaceRect.first, let outputImage = model.outputImage {
            facePreview.image = nil
            print("faceRect = \(faceRect)")
            let size = facePreview.bounds.size
            print("Preview size = \(size)")
            let dx = (faceRect.size.width - size.width)/2
            let dy = (faceRect.size.height - size.height)/2
            print("dx = \(dx)")
            print("dy = \(dy)")
            let cropRect = faceRect.insetBy(dx: dx, dy: dy)
            print("Crop size = \(cropRect)")
            let image = outputImage.cropped(to: cropRect)
            facePreview.image = UIImage(ciImage: image)
        }
    }
    
    @IBAction func dismiss() {
        self.dismiss(animated: true, completion: {
            self.presentationController?.delegate?.presentationControllerDidDismiss?(self.presentationController!)
        })
    }
}
