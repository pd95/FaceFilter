//
//  PreviewImageViewController.swift
//  FaceFilter
//
//  Created by Philipp on 09.04.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import UIKit

class PreviewImageViewController: UIViewController {
    
    @IBOutlet private weak var imageView: UIImageView!

    private let model = AppModel.shared

    var previewRunning = false
    var previewIsObsolete = false
    
    public var pageIndex: Int = -1
    
    public func refreshImage() {
        if !previewRunning {
            previewRunning = true
            let index = pageIndex
            DispatchQueue.global(qos: .background).async {
                let previewImage = self.model.previewImage(for: index)
                DispatchQueue.main.async {
                    if self.pageIndex == index {
                        self.imageView.image = previewImage
                    }
                    self.previewRunning = false
                    if self.previewIsObsolete {
                        self.previewIsObsolete = false
                        self.refreshImage()
                    }
                }
            }
        }
        else {
            previewIsObsolete = true
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        print("PreviewImageViewController \(pageIndex): viewDidLoad")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let cachedImage = model.cachedPreviewImage(for: pageIndex)
        imageView?.image = cachedImage
        if cachedImage == nil {
            refreshImage()
        }
        print("PreviewImageViewController \(pageIndex): viewWillAppear")
    }
}
