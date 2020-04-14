# Face Filter

A simple, quick and dirty iPhone prototype to process an image and pixelate the faces.

Based on Apples Vision framework the app detects faces in the image (load from your photo library) and applies a Core Image filter (Gaussian blur, square or hexagonal pixellate) onto the detected "face areas". 

The resulting filtered image can then be shared.

## Possible improvements

This is not a finished app. It is a first prototype. 
There are various ideas for improvement:

- "live" filter configuration instead of the modal sheet
- manual adjustments (e.g. if a face has not or only partially been detected)
- rewrite as a photo editing extension
- ...

## How to build

1. Install Xcode and open the project `FaceFilter.codeproj`

2. Choose a simulator and press "run"  
   (You will have to add images to the iOS Simulator using drag & drop, the camera is not available here.)

3. If you want to deploy the app to your device, you should checkout `Config.xcconfig` to see what settings need to be set. Especially the `DEVELOPMENT_TEAM` is required to sign the app for physical device deployment.  Afterwards you should select your device and press "run".

If you want to develop you can create a `LocalConfig.xcconfig` file to set `PRODUCT_BUNDLE_IDENTIFIER` and `DEVELOPMENT_TEAM` permanently to your chosen values.

## Demo

![Demo](./Demo-01.gif)
