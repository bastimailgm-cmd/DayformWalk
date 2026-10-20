import Foundation

final class Persistence {
    private let directory: URL
    private let file: URL
    init() throws {
        directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("DayformWalk", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        file = directory.appendingPathComponent("journal.json")
    }
    func load() throws -> Archive {
        guard FileManager.default.fileExists(atPath: file.path) else { return Archive() }
        return try Self.decode(Data(contentsOf: file))
    }
    func save(_ archive: Archive) throws {
        let data = try Self.encode(archive)
        try data.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
    static func encode(_ archive: Archive) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(archive)
    }
    static func decode(_ data: Data) throws -> Archive {
        guard data.count <= 100 * 1024 * 1024 else { throw Archive.ValidationError.invalid }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Archive.self, from: data).validated()
    }
}
