import ArgumentParser
import Foundation

struct Yaml2Json: ParsableCommand {

    @Argument(help: "The root path of the sessions directory")
    var sessionsRootPath: String

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

        for op in operations {

            do {
                // Decode Yaml
                let jsonData = try op.convert()

                if let element = String(data: jsonData, encoding: .utf8) {
                    print("Element: \(element)")
                }
                // Encode JSON

            } catch let error {
                print("Error year \(op.year): \(error)")
            }
        }


    }
}

Yaml2Json.main()
