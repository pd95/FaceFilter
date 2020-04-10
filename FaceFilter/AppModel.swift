//
//  AppModel.swift
//  FaceFilter
//
//  Created by Philipp on 24.03.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import Foundation
import UIKit
import Vision

struct FilterSelection {
    let filterName: String
    let parameterName: String
    let defaultValue: Float
    let minimumValue: Float
    let maximumValue: Float
}

public class AppModel {
    public static let shared = AppModel()
    
    struct DefaultKeys {
        static let currentFilter = "currentFilter"
        static let overshootAmount = "overshootAmount"
    }
    
    private init() {
    }
    
    // MARK: - Current filter selection and parameter handling
    let allowedFilter = [
        FilterSelection(filterName: "CIGaussianBlur", parameterName: "inputRadius", defaultValue: 10, minimumValue: 0, maximumValue: 100),
        FilterSelection(filterName: "CIPixellate", parameterName: "inputScale", defaultValue: 20, minimumValue: 1, maximumValue: 100),
        FilterSelection(filterName: "CIHexagonalPixellate", parameterName: "inputScale", defaultValue: 20, minimumValue: 1, maximumValue: 100),
        FilterSelection(filterName: "", parameterName: "", defaultValue: 1, minimumValue: 1, maximumValue: 1)
    ]
    
    public var currentFilterIndex: Int {
        get {
            allowedFilter.firstIndex { $0.filterName == filterName }!
        }
        set {
            let filterName = allowedFilter[newValue].filterName
            if facePixellator.faces.indices.contains(currentFace) {
                facePixellator.faces[currentFace].filter = CIFilter(name: filterName)
            }
            else {
                facePixellator.faces = facePixellator.faces.map {
                    var face = $0
                    face.filter = CIFilter(name: filterName)
                    return face
                }
            }
            UserDefaults.standard.set(filterName, forKey: DefaultKeys.currentFilter)
        }
    }

    public var filterName: String {
        facePixellator.faces[currentFace].filter?.name ?? ""
    }

    public var filterParameterName: String {
        allowedFilter[currentFilterIndex].parameterName
    }

    public var numberOfFaces: Int {
        facePixellator.faces.count
    }
    
    public var currentFace: Int  = -1

    public var currentParameterValue: Float? {
        get {
            facePixellator.faces[currentFace].filter?.value(forKey: filterParameterName) as? Float
        }
        set {
            facePixellator.faces[currentFace].filter?.setValue(newValue, forKey: filterParameterName)
//            UserDefaults.standard.set(newValue, forKey: filterName)
        }
    }
    
    public var overshootAmount: CGFloat {
        get {
            facePixellator.faces[currentFace].overshoot
        }
        set {
            facePixellator.faces[currentFace].overshoot = newValue
        }
    }
    

    // MARK: - Image processing / face detection
    var facePixellator = FacePixellator()

    public var detectedFaceRect : [CGRect] {
        let r = facePixellator.faces.map { $0.boundingBox }
        return r
    }

    // This method prepares the given UIImage and extracts the location (=Rects) of the faces
    public func detectFaces(in image: UIImage) {
        facePixellator = FacePixellator()
        facePixellator.set(uiImage: image)
        facePixellator.detectFaces()
        
        // Applying default values for filter and overshoot
        let defaultFilterName = UserDefaults.standard.value(forKey: DefaultKeys.currentFilter) as? String ?? "CIPixellate"
        let defaultOvershoot = UserDefaults.standard.value(forKey: DefaultKeys.overshootAmount) as? CGFloat ?? 0.0
        facePixellator.faces = facePixellator.faces.map {
            var face = $0
            face.filter = CIFilter(name: defaultFilterName)
            face.overshoot = defaultOvershoot
            return face
        }
        
    }
        
    private var previewImageCache = [Int:UIImage]()
    
    public func cachedPreviewImage(for index: Int) -> UIImage? {
        return previewImageCache[index]
    }

    public func previewImage(for index: Int = -1) -> UIImage {
        let index = index >= 0 ? index : currentFace
        if facePixellator.faces.indices.contains(index) {
            let face = facePixellator.faces[index]
            let image = UIImage(ciImage: facePixellator.previewImage(for: face))
            previewImageCache[index] = image
            return image
        }
        return UIImage()
    }
    
    public func resultImage() -> UIImage {
        let image = UIImage(ciImage: facePixellator.resultImage())
        return image
    }
}
