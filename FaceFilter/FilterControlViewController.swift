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
    }

    @IBAction func overshootAmountChanged(_ sender: UISlider) {
        overshootAmount.value = round(overshootAmount.value * 10) / 10
        overshootAmountLabel.text = "\(overshootAmount.value)"
        model.overshootAmount = CGFloat(overshootAmount.value)
    }

    @IBAction func filterSelected(_ sender: UISegmentedControl) {
        model.currentFilterIndex = sender.selectedSegmentIndex
        inputScale.maximumValue = model.allowedFilter[model.currentFilterIndex].maximumValue
        inputScale.minimumValue = model.allowedFilter[model.currentFilterIndex].minimumValue
        inputScale.value = model.currentParameterValue
        inputScaleLabel.text = "\(inputScale.value)"
        overshootAmount.value = Float(model.overshootAmount)
        overshootAmountLabel.text = "\(overshootAmount.value)"
    }
    
    @IBAction func dismiss() {
        self.dismiss(animated: true, completion: {
            self.presentationController?.delegate?.presentationControllerDidDismiss?(self.presentationController!)
        })
    }
}
