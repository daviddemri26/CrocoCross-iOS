/// A filtered preview never grants a playable selection.
enum CatalogAvailability: Equatable {
    case available
    case locked(requirement: String? = nil)

    var isUnlocked: Bool {
        if case .available = self { return true }
        return false
    }

    var requirementText: String {
        if case .locked(let requirement) = self, let requirement { return requirement }
        return "Requirements coming soon."
    }
}
