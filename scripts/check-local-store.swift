// Run from the iOS repository root:
// xcrun swiftc -swift-version 6 App/Services/LocalStore.swift scripts/check-local-store.swift -o /tmp/crococross-local-store-check
// /tmp/crococross-local-store-check
// No app data is touched: this harness creates and removes its own temporary directory.
import Foundation

@main struct CheckLocalStore {
    struct Save: Codable, Equatable { let name: String; let score: Int }
    enum Failure: Error { case expectation(String) }

    static func expect(_ result: Bool, _ description: String) throws {
        if !result { throw Failure.expectation(description) }
    }

    static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("CrocoCrossStoreChecks-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LocalStore(rootURL: root)
        try expect(try store.load(Save.self, from: "missing.json") == nil, "Missing save should return nil")
        let first = Save(name: "Test rider", score: 500)
        try store.save(first, to: "progress.json")
        try expect(try store.load(Save.self, from: "progress.json") == first, "Saved value must round-trip")
        let replacement = Save(name: "Test rider", score: 900)
        try store.save(replacement, to: "progress.json")
        try expect(try store.load(Save.self, from: "progress.json") == replacement, "Atomic replacement must read back")
        let savedBytes = try Data(contentsOf: root.appendingPathComponent("progress.json"))
        do {
            _ = try store.load(Save.self, from: "progress.json", version: 2)
            throw Failure.expectation("Unsupported version must throw")
        } catch LocalStore.StoreError.unsupportedVersion(let found, let expected) {
            try expect(found == 1 && expected == 2, "Version error must retain actual and expected versions")
        }
        try expect(try Data(contentsOf: root.appendingPathComponent("progress.json")) == savedBytes, "Version mismatch must preserve the original")
        let corruptBytes = Data("broken json".utf8)
        try corruptBytes.write(to: root.appendingPathComponent("corrupt.json"))
        do {
            _ = try store.load(Save.self, from: "corrupt.json")
            throw Failure.expectation("Corruption must throw")
        } catch LocalStore.StoreError.corruptedFile { }
        try expect(try Data(contentsOf: root.appendingPathComponent("corrupt.json")) == corruptBytes, "Corrupt data must be preserved")
        for invalid in ["../escape.json", "nested/save.json", "", ".", "..", "nested\\save.json"] {
            do {
                try store.save(first, to: invalid)
                throw Failure.expectation("Unsafe filename must fail: \(invalid)")
            } catch LocalStore.StoreError.invalidFilename { }
        }
        try store.remove("progress.json")
        try expect(try store.load(Save.self, from: "progress.json") == nil, "Removed save must be missing")
        try store.remove("progress.json")
        print("PASS: LocalStore round-trip, atomic replacement, missing save, corruption preservation, version preservation, path confinement and idempotent removal.")
    }
}
