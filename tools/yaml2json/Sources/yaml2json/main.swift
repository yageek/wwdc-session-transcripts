import ArgumentParser
import Foundation

struct Yaml2Json: ParsableCommand {

    @Argument(help: "The root path of the sessions directory")
    var sessionsRootPath: String

    @Option(name: .shortAndLong, help: "The output path")
    var output: String

    mutating func run() throws {

        let url = URL(fileURLWithPath: sessionsRootPath)
        // We take the root path and converts all yamls files to json
        let resourceKeys = Set<URLResourceKey>([.nameKey, .isDirectoryKey])
        let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)!

        var yearsMap: [UInt: URL] = [:]

        var currentYear: UInt?
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                    let isDirectory = resourceValues.isDirectory,
                    let name = resourceValues.name
                    else {
                        continue
                }

            if isDirectory, let year = UInt(name) {
                currentYear = year
            } else if name == "_sessions.yml", let year = currentYear {
                yearsMap[year] = fileURL
            }
        }

        // All sessions yamls        
        let operations = yearsMap.map { ParseYamlOperation(year: $0.key, sessionYaml: $0.value) }

        // Retrieve all the sessions
        let years = try operations.map { try $0.parse() }

        let out = OutFormat(events: years)
        // Convert to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(out)

        if !FileManager.default.createFile(atPath: output, contents: data, attributes: nil) {
            print("Error writing file")
        }
    }
}

Yaml2Json.main()
