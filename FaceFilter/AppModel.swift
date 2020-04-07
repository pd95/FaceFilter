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
        FilterSelection(filterName: "CIHexagonalPixellate", parameterName: "inputScale", defaultValue: 20, minimumValue: 1, maximumValue: 100)
    ]
    
    var currentFilterIndex: Int = 1 {
        didSet {
            UserDefaults.standard.set(filterName, forKey: DefaultKeys.currentFilter)
            currentParameterValue = UserDefaults.standard.value(forKey: filterName) as? Float ?? allowedFilter[currentFilterIndex].defaultValue
        }
    }

    var filterName: String {
        allowedFilter[currentFilterIndex].filterName
    }

    var filterParameterName: String {
        allowedFilter[currentFilterIndex].parameterName
    }

    var currentParameterValue: Float = 8 {
        didSet {
            UserDefaults.standard.set(currentParameterValue, forKey: filterName)
        }
    }
    
    var overshootAmount: CGFloat = 0 {
        didSet {
            UserDefaults.standard.set(overshootAmount, forKey: DefaultKeys.overshootAmount)
        }
    }
    

    // MARK: - Image processing / face detection
    var inputImage: CIImage?
    var outputImage: CIImage?
    var maskAccumulator: CIImageAccumulator?

    public var detectedFaceRect = [CGRect]()

    // This method prepares the given UIImage and extracts the location (=Rects) of the faces
    public func detectFaces(in image: UIImage) {
        if let ciImage = image.ciImage {
            inputImage = ciImage
        }
        else {
            inputImage = CIImage(cgImage: image.cgImage!).oriented(CGImagePropertyOrientation(image.imageOrientation))
        }
        guard let ciImage = inputImage else {
            fatalError("Unable to access image data")
        }

        let faceDetection = VNDetectFaceRectanglesRequest()
        let faceDetectionRequest = VNSequenceRequestHandler()
        try? faceDetectionRequest.perform([faceDetection], on: ciImage)
        if let results = faceDetection.results as? [VNFaceObservation] {

            detectedFaceRect.removeAll()
            if !results.isEmpty {

                let size = ciImage.extent.size
                var maxWxH : Float = 0

                for face in results {
                    // Calculate position in image coordinates
                    let faceRect = CGRect(
                        x: face.boundingBox.origin.x * size.width,
                        y: face.boundingBox.origin.y * size.height,
                        width: face.boundingBox.width * size.width,
                        height: face.boundingBox.height * size.height
                    )
                    
                    maxWxH = max(maxWxH, Float(faceRect.size.width), Float(faceRect.size.height))

                    detectedFaceRect.append(faceRect)
                }
                
                currentParameterValue = round(maxWxH / 7.0)
            }
        }
    }
    
    // Applies the face locations to an empty mask (=CIImageAccumulator)
    public func calculateMask() {
        let size = inputImage!.extent.size
        maskAccumulator = CIImageAccumulator(extent: CGRect(x: 0, y: 0, width: size.width, height: size.height), format: CIFormat.ARGB8)
        guard let maskAccumulator = maskAccumulator else {
            fatalError("Unable to create mask accumulator")
        }
        
        let rectGenerator = CIFilter.roundedRectangleGenerator()
        rectGenerator.color = .white
        rectGenerator.extent = maskAccumulator.extent

        let maskCompositingFilter = CIFilter.sourceOverCompositing()
        maskCompositingFilter.inputImage = rectGenerator.outputImage
        maskCompositingFilter.backgroundImage = maskAccumulator.image()

        for faceRect in detectedFaceRect {
            // Slightly increase, as we do not want partial faces be seen
            let adjustedFaceRect = faceRect.insetBy(dx: -faceRect.width * overshootAmount, dy: -faceRect.height * overshootAmount)
            maskAccumulator.setImage(maskCompositingFilter.outputImage!, dirtyRect: adjustedFaceRect)
        }
    }
    
    
    // Apply the user selected filter parameters on the input image and recombines the resulting image using the pre-calculated mask
    public func blurHeads() {

        let ciImage = inputImage!

        let blurredImage = ciImage.applyingFilter(filterName, parameters: [filterParameterName: currentParameterValue])

        let compositeFilter = CIFilter.blendWithMask()
        compositeFilter.backgroundImage = ciImage
        compositeFilter.inputImage = blurredImage
        compositeFilter.maskImage = maskAccumulator?.image()

        outputImage = compositeFilter.outputImage
    }
    
    public func resultImage() -> UIImage {
        return UIImage(ciImage: outputImage!)
    }
}
