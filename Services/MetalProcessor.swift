
import Foundation
import AVFoundation
import Metal
import MetalKit
import CoreImage

class MetalProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, MTKViewDelegate {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var ciContext: CIContext!
    var library: MTLLibrary!

    var mtkView: MTKView?
    var selectedFilter: FilterType = .none

    private let captureSession = AVCaptureSession()
    private var currentPixelBuffer: CVPixelBuffer?

    private var pipelineStates: [FilterType: MTLComputePipelineState] = [:]

    func setMetalView(_ view: MTKView) {
        self.mtkView = view
        self.device = view.device
        self.commandQueue = device.makeCommandQueue()
        self.ciContext = CIContext(mtlDevice: device)

        do {
            library = device.makeDefaultLibrary()
            try compileShaders()
        } catch {
            print("[Metal Error] Failed to compile shaders: \(error)")
        }
    }

    func setupCamera() {
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }

        captureSession.beginConfiguration()
        if captureSession.canAddInput(input) { captureSession.addInput(input) }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
        if captureSession.canAddOutput(output) { captureSession.addOutput(output) }

        captureSession.commitConfiguration()
        captureSession.startRunning()
    }

    private func compileShaders() throws {
        let shaderNames: [FilterType: String] = [
            .blur: "gaussianBlur",
            .edge: "edgeDetection",
            .chromatic: "chromaticAberration",
            .toneMap: "toneMapping"
        ]

        for (type, functionName) in shaderNames {
            if let function = library.makeFunction(name: functionName) {
                pipelineStates[type] = try device.makeComputePipelineState(function: function)
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        currentPixelBuffer = buffer
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let buffer = currentPixelBuffer,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        let inputTexture: MTLTexture
        let outputTexture: MTLTexture

        do {
            inputTexture = try texture(from: buffer)
            outputTexture = try makeEmptyTexture(width: inputTexture.width, height: inputTexture.height)
        } catch {
            print("[Metal Error] Texture conversion failed: \(error)")
            return
        }

        if let pipeline = pipelineStates[selectedFilter] {
            let encoder = commandBuffer.makeComputeCommandEncoder()
            encoder?.setComputePipelineState(pipeline)
            encoder?.setTexture(inputTexture, index: 0)
            encoder?.setTexture(outputTexture, index: 1)

            if selectedFilter == .chromatic {
                var offset: Float = 2.0
                encoder?.setBytes(&offset, length: MemoryLayout<Float>.size, index: 0)
            } else if selectedFilter == .toneMap {
                var exposure: Float = 1.0
                encoder?.setBytes(&exposure, length: MemoryLayout<Float>.size, index: 0)
            }

            let threadGroupSize = MTLSizeMake(8, 8, 1)
            let threadGroups = MTLSize(
                width: (inputTexture.width + 7) / 8,
                height: (inputTexture.height + 7) / 8,
                depth: 1)

            encoder?.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
            encoder?.endEncoding()

            // Render final output
            if let blit = commandBuffer.makeBlitCommandEncoder() {
                blit.copy(from: outputTexture,
                          sourceSlice: 0,
                          sourceLevel: 0,
                          sourceOrigin: .zero,
                          sourceSize: MTLSizeMake(outputTexture.width, outputTexture.height, 1),
                          to: drawable.texture,
                          destinationSlice: 0,
                          destinationLevel: 0,
                          destinationOrigin: .zero)
                blit.endEncoding()
            }
        } else {
            ciContext.render(CIImage(cvPixelBuffer: buffer),
                             to: drawable.texture,
                             commandBuffer: commandBuffer,
                             bounds: CGRect(origin: .zero, size: view.drawableSize),
                             colorSpace: CGColorSpaceCreateDeviceRGB())
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    private func texture(from pixelBuffer: CVPixelBuffer) throws -> MTLTexture {
        var texture: MTLTexture?
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                         width: CVPixelBufferGetWidth(pixelBuffer),
                                                                         height: CVPixelBufferGetHeight(pixelBuffer),
                                                                         mipmapped: false)
        textureDescriptor.usage = [.shaderRead, .shaderWrite]

        let textureCache: CVMetalTextureCache
        var tempCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &tempCache)
        textureCache = tempCache!

        var tempTexture: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, .bgra8Unorm, textureDescriptor.width, textureDescriptor.height, 0, &tempTexture)
        if let tempTexture = tempTexture {
            texture = CVMetalTextureGetTexture(tempTexture)
        }

        guard let finalTexture = texture else {
            throw NSError(domain: "Metal", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create texture from pixel buffer"])
        }

        return finalTexture
    }

    private func makeEmptyTexture(width: Int, height: Int) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                  width: width,
                                                                  height: height,
                                                                  mipmapped: false)
        descriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw NSError(domain: "Metal", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create output texture"])
        }

        return texture
    }
} 
