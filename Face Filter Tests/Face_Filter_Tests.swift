//
//  Face_Filter_Tests.swift
//  Face Filter Tests
//
//  Created by Philipp on 07.04.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import XCTest
import Face_Filter

class Face_Filter_Tests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAppModel() throws {
        // fetch testing image
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "test_classic_composer", ofType: "jpg")!

        // Load image
        let image = UIImage(contentsOfFile: path)!

        let model = AppModel.shared
        
        // Test face detection
        model.detectFaces(in: image)
        XCTAssert(model.numberOfFaces == 13, "Unexpected count of detected faces: \(model.numberOfFaces)")

        model.currentFilterIndex = 0 // Use Gaussian blur
        
        // Check result image
        let resultImage = model.resultImage()
        XCTAssertNotNil(resultImage)

        // Test face detection on result image: no faces should be detected
        model.detectFaces(in: resultImage)
        XCTAssert(model.numberOfFaces == 0, "Unexpected count of detected faces: \(model.numberOfFaces)")
    }
    
    func testFacePixellator() {
        // fetch testing image
        let bundle = Bundle(for: type(of: self))
        let testImageUrl = bundle.url(forResource: "test_classic_composer", withExtension: "jpg")!

        let pixellator = FacePixellator()
        pixellator.set(imageFromUrl: testImageUrl)
        pixellator.detectFaces()
        
        let faceCount = pixellator.faces.count
        XCTAssert(faceCount == 13, "Unexpected count of detected faces: \(faceCount)")
        
        let face = pixellator.faces[0]
        let preview = pixellator.previewImage(for: face)
        
        let result = pixellator.resultImage()
        let resultUiImage = UIImage(ciImage: result)

    }
}
