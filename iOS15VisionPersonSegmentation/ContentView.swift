//
//  ContentView.swift
//  iOS15VisionPersonSegmentation
//
//  Created by Anupam Chugh on 29/06/21.
//

import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import VideoToolbox

struct ContentView: View {
    
    @State var finalOutputImage : UIImage = UIImage(named: "background")!
    @State var outputImage : UIImage = UIImage(named: "background")!
    @State var inputImage : UIImage = UIImage(named: "sample")!
    
    var body: some View {
        
        VStack(alignment: .center){
                    
                    Image(uiImage: inputImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)

                    Image(uiImage: outputImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        
                    Image(uiImage: finalOutputImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                }.task {
                    runVisionRequest()
                    //runCoreImage()
                }
    }
    
    
    func runCoreImage(){
        let filter = CIFilter.personSegmentation()
        let input = CIImage(cgImage: inputImage.cgImage!)
        filter.inputImage = CIImage(cgImage: inputImage.cgImage!)

        if let maskImage = filter.outputImage{
        
            let ciContext = CIContext(options: nil)
            
            let maskScaleX = input.extent.width / maskImage.extent.width
            let maskScaleY = input.extent.height / maskImage.extent.height
            
            let maskScaled =  maskImage.transformed(by: __CGAffineTransformMake(maskScaleX, 0, 0, maskScaleY, 0, 0))
            
            let maskRef = ciContext.createCGImage(maskScaled, from: maskScaled.extent)
            self.outputImage = UIImage(cgImage: maskRef!)

        }
    }
    
    func runVisionRequest(){
        
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .fast
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        let handler = VNImageRequestHandler(cgImage: inputImage.cgImage!, options: [:])
        
        do {
            try handler.perform([request])
            
            let mask = request.results!.first!
            let maskBuffer = mask.pixelBuffer
            
            maskInputImage(maskBuffer)
            
        }catch {
            print(error)
        }
    }
    
    func maskInputImage(_ buffer: CVPixelBuffer){
        
        let bgImage = UIImage(named: "background")!
        let background = CIImage(cgImage: bgImage.cgImage!)
        let input = CIImage(cgImage: inputImage.cgImage!)
        let mask = CIImage(cvPixelBuffer: buffer)
        
        
        let maskScaleX = input.extent.width / mask.extent.width
        let maskScaleY = input.extent.height / mask.extent.height
        
        let maskScaled =  mask.transformed(by: __CGAffineTransformMake(maskScaleX, 0, 0, maskScaleY, 0, 0))
        
        let backgroundScaleX = input.extent.width / background.extent.width
        let backgroundScaleY = input.extent.height / background.extent.height
        
        let backgroundScaled =  background.transformed(by: __CGAffineTransformMake(backgroundScaleX, 0, 0, backgroundScaleY, 0, 0))
        
        
        let blendFilter = CIFilter.blendWithMask()
        
        blendFilter.inputImage = input
        blendFilter.backgroundImage = backgroundScaled
        blendFilter.maskImage = maskScaled

        if let blendedImage = blendFilter.outputImage{
        
            let ciContext = CIContext(options: nil)
            let filteredImageRef = ciContext.createCGImage(blendedImage, from: blendedImage.extent)
            let maskDisplayRef = ciContext.createCGImage(maskScaled, from: maskScaled.extent)
            
            self.outputImage = UIImage(cgImage: maskDisplayRef!)
            self.finalOutputImage = UIImage(cgImage: filteredImageRef!)
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewInterfaceOrientation(.landscapeLeft)
            
    }
}


extension UIImage {
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)

        guard let cgImage = cgImage else {
            return nil
        }

        self.init(cgImage: cgImage)
    }
}
