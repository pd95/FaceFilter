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
    var previewRunning = false
    var previewIsObsolete = false
    
    private let model = AppModel.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterSegmentControl.selectedSegmentIndex = model.currentFilterIndex
        filterSelected(filterSegmentControl)
    }
    
    @IBAction func scaleChanged(_ sender: UISlider) {
        inputScale.value = floor(inputScale.value)
        inputScaleLabel.text = "\(inputScale.value)"
        if model.currentParameterValue != inputScale.value {
            model.currentParameterValue = inputScale.value
            refreshPreview()
        }
    }

    @IBAction func overshootAmountChanged(_ sender: UISlider) {
        let newValue = round(overshootAmount.value * 100) / 100
        overshootAmount.value = newValue
        overshootAmountLabel.text = "\(Int(newValue * 100))%"
        if model.overshootAmount != CGFloat(newValue) {
            model.overshootAmount = CGFloat(overshootAmount.value)
            refreshPreview()
        }
    }

    @IBAction func filterSelected(_ sender: UISegmentedControl) {
        model.currentFilterIndex = sender.selectedSegmentIndex
        inputScale.maximumValue = model.allowedFilter[model.currentFilterIndex].maximumValue
        inputScale.minimumValue = model.allowedFilter[model.currentFilterIndex].minimumValue
        inputScale.value = model.currentParameterValue
        inputScaleLabel.text = "\(inputScale.value)"
        overshootAmount.value = Float(model.overshootAmount)
        overshootAmountLabel.text = "\(Int(overshootAmount.value * 100))%"

        refreshPreview()
    }
    
    func refreshPreview() {
        if !previewRunning {
            previewRunning = true
            DispatchQueue.global(qos: .userInitiated).async {
                let previewImage = self.model.previewImage()
                DispatchQueue.main.async {
                    self.facePreview.image = previewImage
                    self.previewRunning = false
                    if self.previewIsObsolete {
                        self.previewIsObsolete = false
                        self.refreshPreview()
                    }
                }
            }
        }
        else {
            previewIsObsolete = true
        }
    }
    
    @IBAction func dismiss() {
        self.dismiss(animated: true, completion: {
            self.presentationController?.delegate?.presentationControllerDidDismiss?(self.presentationController!)
        })
    }
}
