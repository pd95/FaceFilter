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

    var imageViewController : PreviewImageViewController? {
        didSet {
            let index = imageViewController?.pageIndex
            model.currentFace = index ?? -1
            syncModel2UI()
        }
    }
    var nextImageViewController: PreviewImageViewController?
    
    private let model = AppModel.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        syncModel2UI()
    }
    
    func syncModel2UI() {
        filterSegmentControl.selectedSegmentIndex = model.currentFilterIndex

        if let parameterValue = model.currentParameterValue {
            inputScale.isHidden = false
            inputScale.value = parameterValue
            inputScaleLabel.isHidden = false
            inputScaleLabel.text = "\(parameterValue)"
            inputScale.minimumValue = model.filterMinimumValue
            inputScale.maximumValue = model.filterMaximumValue
        }
        else {
            inputScale.isHidden = true
            inputScaleLabel.isHidden = true
        }

        let overshoot = model.overshootAmount
        overshootAmount.value = Float(overshoot)
        overshootAmountLabel.text = "\(Int(overshoot * 100))%"
    }
    
    @IBAction func scaleChanged(_ sender: UISlider) {
        let newValue = floor(inputScale.value)
        inputScale.value = newValue
        inputScaleLabel.text = "\(newValue)"
        if model.currentParameterValue != newValue {
            model.currentParameterValue = newValue
            refreshPreview()
        }
    }

    @IBAction func overshootAmountChanged(_ sender: UISlider) {
        let newValue = round(overshootAmount.value * 100) / 100
        overshootAmount.value = newValue
        overshootAmountLabel.text = "\(Int(newValue * 100))%"
        if model.overshootAmount != CGFloat(newValue) {
            model.overshootAmount = CGFloat(newValue)
            refreshPreview()
        }
    }

    @IBAction func filterSelected(_ sender: UISegmentedControl) {
        model.currentFilterIndex = sender.selectedSegmentIndex
        syncModel2UI()
        refreshPreview()
    }
    
    func refreshPreview() {
        imageViewController?.refreshImage()
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
                vc.view.backgroundColor = .systemGray4
                let childVC = previewViewController(at: 0)!
                imageViewController = childVC as? PreviewImageViewController
                vc.setViewControllers([childVC], direction: .forward, animated: false, completion: nil)
            }
        }
    }

    // Helper routine to create preview controllers for the page view
    func previewViewController(at index: Int) -> UIViewController? {
        let imageVC = storyboard?.instantiateViewController(identifier: "PreviewImageViewController") as! PreviewImageViewController
        imageVC.pageIndex = index
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
        if index >= model.numberOfFaces {
            return nil
        }

        return previewViewController(at: index)
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return model.numberOfFaces
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let currentVC = pendingViewControllers.first as? PreviewImageViewController else { return }
        nextImageViewController = currentVC
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            imageViewController = nextImageViewController
        }
    }
}
