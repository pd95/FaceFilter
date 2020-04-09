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

    var faceCount = 0
    var currentFace = -1
    var previewRunning = false
    var previewIsObsolete = false
    
    var imageViewController : PreviewImageViewController?
    
    private let model = AppModel.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterSegmentControl.selectedSegmentIndex = model.currentFilterIndex
        filterSelected(filterSegmentControl)
        faceCount = model.detectedFaceRect.count
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
            model.syncSettings(for: currentFace)
            DispatchQueue.global(qos: .userInitiated).async {
                let previewImage = self.model.previewImage()
                DispatchQueue.main.async {
                    self.imageViewController?.image = previewImage
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
    
    // Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedPageViewVC" {
            // Initialize the page view controller
            if let vc = segue.destination as? UIPageViewController {
                vc.dataSource = self
                vc.delegate = self
                vc.setViewControllers([previewViewController(at: 0)!], direction: .forward, animated: false, completion: nil)
            }
        }
    }

    // Helper routine to create preview controllers for the page view
    func previewViewController(at index: Int) -> UIViewController? {
        let imageVC = storyboard?.instantiateViewController(identifier: "PreviewImageViewController") as! PreviewImageViewController
        imageVC.pageIndex = index
        imageVC.image = model.previewImage(for: index)
        
        return imageVC
    }
}


extension FilterControlViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let beforeVC = viewController as? PreviewImageViewController else { return nil }
        
        let index = beforeVC.pageIndex - 1
        if index < 0 {
            return nil
        }

        return previewViewController(at: index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let afterVC = viewController as? PreviewImageViewController else { return nil }

        let index = afterVC.pageIndex + 1
        if index >= faceCount {
            return nil
        }

        return previewViewController(at: index)
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return faceCount
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let currentVC = pendingViewControllers.first as? PreviewImageViewController else { return }
        imageViewController = currentVC
    }
}
