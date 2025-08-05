import SwiftUI
import MetalKit

struct CameraView: UIViewRepresentable {
    @ObservedObject var viewModel: CameraViewModel

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.framebufferOnly = false
        mtkView.delegate = viewModel.processor

        viewModel.processor.setMetalView(mtkView)
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // No-op
    }
}

struct CameraViewContainer: View {
    @StateObject private var viewModel = CameraViewModel()

    var body: some View {
        ZStack {
            CameraView(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(FilterType.allCases, id: \ .self) { filter in
                            Button(action: {
                                viewModel.selectedFilter = filter
                            }) {
                                Text(filter.rawValue)
                                    .padding(10)
                                    .background(viewModel.selectedFilter == filter ? Color.blue : Color.white)
                                    .foregroundColor(.black)
                                    .cornerRadius(8)
                            }
                        }
                    }.padding()
                }
            }
        }
        .onAppear {
            viewModel.setupSession()
        }
    }
}
