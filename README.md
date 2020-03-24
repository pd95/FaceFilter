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

## Demo

![Demo](./Demo-01.gif)
