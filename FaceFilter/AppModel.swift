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
        if let filterName = UserDefaults.standard.value(forKey: DefaultKeys.currentFilter) as? String {
            currentFilterIndex = allowedFilter.firstIndex { $0.filterName == filterName } ?? 1
            currentParameterValue = UserDefaults.standard.value(forKey: filterName) as? Float ?? allowedFilter[currentFilterIndex].defaultValue
            overshootAmount = UserDefaults.standard.value(forKey: DefaultKeys.overshootAmount) as? CGFloat ?? 0
        }
    }
    
    // MARK: - Current filter selection and parameter handling
    let allowedFilter = [
        FilterSelection(filterName: "CIGaussianBlur", parameterName: "inputRadius", defaultValue: 10, minimumValue: 0, maximumValue: 100),
        FilterSelection(filterName: "CIPixellate", parameterName: "inputScale", defaultValue: 20, minimumValue: 1, maximumValue: 100),
        FilterSelection(filterName: "CIHexagonalPixellate", parameterName: "inputScale", defaultValue: 20, minimumValue: 1, maximumValue: 100),
        FilterSelection(filterName: "", parameterName: "", defaultValue: 1, minimumValue: 1, maximumValue: 1)
    ]
    
    public var currentFilterIndex: Int = 1 {
        didSet {
            UserDefaults.standard.set(filterName, forKey: DefaultKeys.currentFilter)
            currentParameterValue = UserDefaults.standard.value(forKey: filterName) as? Float ?? allowedFilter[currentFilterIndex].defaultValue
        }
    }

    public var filterName: String {
        allowedFilter[currentFilterIndex].filterName
    }

    public var filterParameterName: String {
        allowedFilter[currentFilterIndex].parameterName
    }

    public var currentParameterValue: Float = 8 {
        didSet {
            UserDefaults.standard.set(currentParameterValue, forKey: filterName)
        }
    }
    
    public var overshootAmount: CGFloat = 0 {
        didSet {
            UserDefaults.standard.set(overshootAmount, forKey: DefaultKeys.overshootAmount)
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
    }
    
    // Applies the face locations to an empty mask (=CIImageAccumulator)
    @available(*, deprecated, message: "Not needed anymore")
    public func calculateMask() {
    }
    
    
    // Apply the user selected filter parameters on the input image and recombines the resulting image using the pre-calculated mask
    @available(*, deprecated, message: "Not needed anymore")
    public func blurHeads() {
    }
    
    public func syncSettings(for index: Int = -1) {
        // Apply the selected filter to all the faces
        if index < 0 {
            facePixellator.faces = facePixellator.faces.map {
                var newFace = $0
                newFace.setFilter(name: filterName == "" ? nil : filterName, parameter: [filterParameterName : currentParameterValue])
                newFace.overshoot = overshootAmount
                return newFace
            }
        }
        else {
            var newFace = facePixellator.faces[index]
            newFace.setFilter(name: filterName == "" ? nil : filterName, parameter: [filterParameterName : currentParameterValue])
            newFace.overshoot = overshootAmount
            facePixellator.faces[index] = newFace
        }
    }
    
    public func previewImage(for index: Int = 0) -> UIImage {
        if facePixellator.faces.indices.contains(index) {
            let face = facePixellator.faces [index]
            let image = UIImage(ciImage: facePixellator.previewImage(for: face))
            return image
        }
        return UIImage()
    }
    
    public func resultImage() -> UIImage {
        let image = UIImage(ciImage: facePixellator.resultImage())
        return image
    }
}
