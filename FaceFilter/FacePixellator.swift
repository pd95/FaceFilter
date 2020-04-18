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
        
        public var filter: CIFilter? = nil
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

    public func addFace(at location: CGPoint) {

        // Try to evaluate the average face rect
        var avgWidth: CGFloat = 0
        var avgHeight: CGFloat = 0
        faces.forEach { (face) in
            avgWidth += face.boundingBox.width
            avgHeight += face.boundingBox.height
        }
        
        // If none was found: take a "sane" default
        if avgWidth == 0 || avgHeight == 0 {
            let size = inputImage.extent.size
            avgWidth  = 1 / 10
            avgHeight = size.width/size.height / 10
        }
        else {
            avgWidth /= CGFloat(faces.count)
            avgHeight /= CGFloat(faces.count)
        }

        // Create the bounding box
        var boundingBox = CGRect(x: location.x - avgWidth / 2, y: location.y - avgHeight / 2, width: avgWidth, height: avgHeight)
        
        // Clamp to the visible area
        boundingBox = boundingBox.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))

        faces.append(FilteredFace(boundingBox: boundingBox, filter: CIFilter.pixellate()))
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
                    faces.append(FilteredFace(boundingBox: face.boundingBox, filter: CIFilter.pixellate()))
                }
            }
        }
    }
    
    
    // Return a CIImage for the given face with the pixellation filter applied
    public func previewImage(for face: FilteredFace, areaIncreaseFactor: CGFloat = 0.4, areaIncreaseOffset: CGFloat = 0.1) -> CIImage {
        // Calculate face position in image coordinates
        let size = inputImage.extent.size
        let faceRect = CGRect(
            x: face.boundingBox.origin.x * size.width,
            y: face.boundingBox.origin.y * size.height,
            width: face.boundingBox.width * size.width,
            height: face.boundingBox.height * size.height
        )

        // For the preview the crop area must be slightly bigger
        let dx = -faceRect.size.width * (ceil((face.overshoot + 0.01)/areaIncreaseFactor) * areaIncreaseFactor + areaIncreaseOffset)
        let dy = -faceRect.size.height * (ceil((face.overshoot + 0.01)/areaIncreaseFactor) * areaIncreaseFactor + areaIncreaseOffset)
        let cropRect = faceRect.insetBy(dx: dx, dy: dy)

        // In the cropped image the face somewhere else
        let previewOrigin = CGPoint(x: faceRect.origin.x - cropRect.origin.x, y: faceRect.origin.y - cropRect.origin.y)
        let previewInput = inputImage
            .cropped(to: cropRect)
            .transformed(by: .init(translationX: -cropRect.minX, y: -cropRect.minY))

        // Apply selected filter with parameters
        let outputImage : CIImage
        if let filter = face.filter {
            
            let adjustedFaceRect = CGRect(origin: previewOrigin, size: faceRect.size)
                .insetBy(dx: -faceRect.width * face.overshoot,
                         dy: -faceRect.height * face.overshoot)
            
            filter.setValue(previewInput, forKey: kCIInputImageKey)
            let filteredImage = filter.outputImage!
                .cropped(to: adjustedFaceRect)

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
            if let filter = face.filter {

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

                filter.setValue(faceImage, forKey: kCIInputImageKey)
                let filteredImage = filter.outputImage!

                // Compose filtered and original image
                outputImage = filteredImage.composited(over: outputImage)
            }
        }
        outputImage = outputImage.cropped(to: inputImage.extent)

        return outputImage
    }
    
    public func overviewImage(singleFaceWidth faceWidth: CGFloat = 200) -> CIImage {
        let numFaces = faces.count
        let numColumns = Int(Float(numFaces).squareRoot())
        let numRows = Int(ceil(Float(numFaces) / Float(numColumns)))

        let outputSize = CGSize(width: CGFloat(numColumns) * faceWidth, height: CGFloat(numRows) * faceWidth)
        var outputImage : CIImage = CIImage(color: .black)
        for (index, face) in faces.enumerated() {
            
            let faceImage = previewImage(for: face, areaIncreaseFactor: 0.2)
            let faceSize = faceImage.extent.size

            let x = index / numRows
            let y = numRows - 1 - index % numRows

            let processedImage = faceImage
                .transformed(by: .init(scaleX: faceWidth / faceSize.width, y: faceWidth / faceSize.height))
                .transformed(by: .init(translationX: CGFloat(x) * faceWidth, y: CGFloat(y) * faceWidth))

            // Compose filtered and original image
            outputImage = processedImage.composited(over: outputImage)
        }
        
        outputImage = outputImage
            .cropped(to: CGRect(origin: .zero, size: outputSize))

        return outputImage
    }
}

