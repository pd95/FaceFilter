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

    public var pageIndex: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("PreviewImageViewController \(pageIndex): viewDidLoad")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        print("PreviewImageViewController \(pageIndex): viewWillAppear")
        imageView.image = image
    }
    
    public var image: UIImage? {
        didSet {
            print("PreviewImageViewController \(pageIndex): set image")
            imageView?.image = image
        }
    }
}
