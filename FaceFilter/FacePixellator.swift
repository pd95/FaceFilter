//
//  FacePixellator.swift
//  FaceFilter
//
//  Created by Philipp on 09.04.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import Foundation
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

public class FacePixellator {
    
    public struct FilteredFace {
        public let boundingBox: CGRect
        
        public var overshoot: CGFloat = 0.0
        
        public var filterName: String? = nil
        public var filterParameter: [String: Any] = [:]

        public mutating func setFilter(name: String?, parameter: [String: Any] = [:]) {
            filterName = name
            filterParameter = parameter
        }
    }
    
    var inputImage: CIImage = .init()

    public var faces: [FilteredFace] = []
    
    public init() {}

    public func set(image: CIImage) {
        inputImage = image
    }
    
    public func set(imageFromUrl: URL) {
        set(image: CIImage(contentsOf: imageFromUrl)!)
    }
    
    public func set(uiImage: UIImage) {
        if let ciImage = uiImage.ciImage {
            set(image: ciImage)
        }
        else {
            set(image: CIImage(cgImage: uiImage.cgImage!).oriented(CGImagePropertyOrientation(uiImage.imageOrientation)))
        }
    }


    // Use Vision framework to detect faces in the image
    public func detectFaces() {
        let faceDetection = VNDetectFaceRectanglesRequest()
        let faceDetectionRequest = VNImageRequestHandler(ciImage: inputImage, options: [:])
        try? faceDetectionRequest.perform([faceDetection])
        if let results = faceDetection.results as? [VNFaceObservation] {
            if !results.isEmpty {
                for face in results {
                    // Create Face structure with preview image
                    faces.append(FilteredFace(boundingBox: face.boundingBox, filterName: "CIPixellate"))
                }
            }
        }
    }
    
    
    // Return a CIImage for the given face with the pixellation filter applied
    public func previewImage(for face: FilteredFace) -> CIImage {
        // Calculate face position in image coordinates
        let size = inputImage.extent.size
        let faceRect = CGRect(
            x: face.boundingBox.origin.x * size.width,
            y: face.boundingBox.origin.y * size.height,
            width: face.boundingBox.width * size.width,
            height: face.boundingBox.height * size.height
        )

        // For the preview the crop area must be slightly bigger
        let dx = -faceRect.size.width * 0.4
        let dy = -faceRect.size.height * 0.4
        let cropRect = faceRect.insetBy(dx: dx, dy: dy)

        // In the cropped image the face somewhere else
        let previewOrigin = CGPoint(x: faceRect.origin.x - cropRect.origin.x, y: faceRect.origin.y - cropRect.origin.y)
        let previewInput = inputImage
            .cropped(to: cropRect)
            .transformed(by: .init(translationX: -cropRect.minX, y: -cropRect.minY))

        // Apply selected filter with parameters
        let outputImage : CIImage
        if let filterName = face.filterName {
            
            let adjustedFaceRect = CGRect(origin: previewOrigin, size: faceRect.size)
                .insetBy(dx: -faceRect.width * face.overshoot,
                         dy: -faceRect.height * face.overshoot)
            
            let filteredImage = previewInput
                .cropped(to: adjustedFaceRect)
                .applyingFilter(filterName, parameters: face.filterParameter)

            outputImage = filteredImage
                .composited(over: previewInput)
                .cropped(to: previewInput.extent)
        }
        else {
            outputImage = previewInput
        }


        return outputImage
    }

    
    // Compose the final image by applying the filtered faces
    public func resultImage() -> CIImage {

        let size = inputImage.extent.size

        var outputImage : CIImage = inputImage
        for face in faces {
            // Apply selected filter with parameters
            if let filterName = face.filterName {

                // Calculate face position in image coordinates
                let faceRect = CGRect(
                    x: face.boundingBox.origin.x * size.width,
                    y: face.boundingBox.origin.y * size.height,
                    width: face.boundingBox.width * size.width,
                    height: face.boundingBox.height * size.height
                )
                
                // Apply selected overshoot
                let overshoot = face.overshoot
                let adjustedFaceRect = faceRect.insetBy(dx: -faceRect.width * overshoot, dy: -faceRect.height * overshoot)
                
                let faceImage = inputImage.cropped(to: adjustedFaceRect)

                let filteredImage = faceImage.applyingFilter(filterName, parameters: face.filterParameter)

                // Compose filtered and original image
                outputImage = filteredImage.composited(over: outputImage)
            }
        }
        outputImage = outputImage.cropped(to: inputImage.extent)

        return outputImage
    }
}

