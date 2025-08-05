import Foundation
import Combine
import AVFoundation

class CameraViewModel: ObservableObject {
    @Published var selectedFilter: FilterType = .none {
        didSet {
            processor.selectedFilter = selectedFilter
        }
    }

    let processor = MetalProcessor()

    func setupSession() {
        processor.setupCamera()
    }
}
