import Foundation

/// Immutable registration token. NotificationCenter supports removing observers from any thread.
/// Wrapping its unannotated NSObjectProtocol token makes actor deinitialization safe under Swift 6.
final class NotificationObservation: @unchecked Sendable {
    private let token: NSObjectProtocol
    init(_ token: NSObjectProtocol) { self.token = token }
    deinit { NotificationCenter.default.removeObserver(token) }
}

/// Small versioned JSON files. Callers serialize access to each filename (the app services use MainActor).
/// Missing files return nil. Invalid or newer saves are preserved and produce an explicit error.
struct LocalStore: Sendable {
    enum StoreError: LocalizedError {
        case invalidFilename
        case unsupportedVersion(found: Int, expected: Int)
        case corruptedFile(String)

        var errorDescription: String? {
            switch self {
            case .invalidFilename: "The save filename is invalid."
            case .unsupportedVersion: "This save belongs to a different app version."
            case .corruptedFile(let name): "The saved data in \(name) could not be read."
            }
        }
    }

    private struct Envelope<Value: Codable>: Codable {
        let version: Int
        let value: Value
    }
    private struct Header: Decodable { let version: Int }
    let rootURL: URL

    init(rootURL: URL? = nil) {
        self.rootURL = rootURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CrocoCross", isDirectory: true)
    }

    func load<Value: Codable>(_ type: Value.Type, from filename: String, version: Int = 1) throws -> Value? {
        let url = try fileURL(filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let header: Header
        do { header = try decoder.decode(Header.self, from: data) }
        catch { throw StoreError.corruptedFile(filename) }
        guard header.version == version else {
            throw StoreError.unsupportedVersion(found: header.version, expected: version)
        }
        do { return try decoder.decode(Envelope<Value>.self, from: data).value }
        catch { throw StoreError.corruptedFile(filename) }
    }

    func save<Value: Codable>(_ value: Value, to filename: String, version: Int = 1) throws {
        let url = try fileURL(filename)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(Envelope(version: version, value: value))
        #if os(iOS)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: url, options: .atomic)
        #endif
    }

    func remove(_ filename: String) throws {
        let url = try fileURL(filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private func fileURL(_ filename: String) throws -> URL {
        guard !filename.isEmpty, filename != ".", filename != "..",
              !filename.contains("/"), !filename.contains("\\"), !filename.contains("\0") else {
            throw StoreError.invalidFilename
        }
        return rootURL.appendingPathComponent(filename, isDirectory: false)
    }
}
