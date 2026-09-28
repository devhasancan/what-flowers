import Foundation

enum FlowerState {
    case empty
    case loading
    case success(FlowerPresentation)
    case failure(message: String)
}
