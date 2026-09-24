struct CatalogProgress: Equatable {
    let current: Int
    let target: Int
    var fraction: Double { min(1, Double(current) / Double(max(1, target))) }
    var text: String { "\(min(current, target)) / \(target)" }
}

/// A filtered preview never grants a playable selection; claiming is a separate action.
enum CatalogAvailability: Equatable {
    case available
    case locked(requirement: String? = nil, progress: CatalogProgress? = nil)
    case readyToUnlock(requirement: String, progress: CatalogProgress)

    var isUnlocked: Bool {
        if case .available = self { return true }
        return false
    }
    var isReadyToUnlock: Bool {
        if case .readyToUnlock = self { return true }
        return false
    }
    var progress: CatalogProgress? {
        switch self {
        case .available: nil
        case .locked(_, let progress): progress
        case .readyToUnlock(_, let progress): progress
        }
    }
    var requirementText: String {
        switch self {
        case .locked(let requirement, _): requirement ?? "Requirements coming soon."
        case .readyToUnlock(let requirement, _): requirement
        case .available: ""
        }
    }
}
