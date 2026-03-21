import Foundation

enum WMError: LocalizedError, Equatable {
    case stageHasModels(stageName: String)
    case invalidModelCount
    case stageNotFound
    case projectNotFound
    case collectionNotFound
    case emptyName
    case insufficientModelsAtStage

    var errorDescription: String? {
        switch self {
        case .stageHasModels(let stageName):
            return "Cannot delete stage '\(stageName)': models are currently in this stage."
        case .invalidModelCount:
            return "Model count must be greater than zero."
        case .stageNotFound:
            return "The specified stage could not be found."
        case .projectNotFound:
            return "The specified project could not be found."
        case .collectionNotFound:
            return "The specified collection could not be found."
        case .emptyName:
            return "Name cannot be empty."
        case .insufficientModelsAtStage:
            return "Not enough models at the source stage to perform this move."
        }
    }
}
