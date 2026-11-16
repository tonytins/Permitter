import Foundation

#if canImport(Glibc)
    import Glibc
#elseif canImport(Darwin)
    import Darwin
#endif

private let usage = """
    Usage: GenerateLicenseCatalog --resources PATH --output PATH

    Generates LicenseCatalogData.swift from the JSON metadata and plain text
    files vendored under PATH. The build-tool plugin runs this executable and
    compiles its output into the Permitter target.
    """

private struct LicenseEntry: Decodable {
    let id: String
    let replace: ReplacementEntry?
    let copyright: String?
    let optional: [String]?
}

private struct ReplacementEntry: Decodable {
    let year: String?
    let name: String?
}

private struct ExceptionEntry: Decodable {
    let id: String
    let with: [String]?
    let optional: [String]?
}

private enum GeneratorError: Error, CustomStringConvertible {
    case message(String)

    var description: String {
        switch self {
        case .message(let message):
            return message
        }
    }
}

private func parseArguments() throws -> (resources: URL, output: URL) {
    var resources: URL?
    var output: URL?
    var arguments = Array(CommandLine.arguments.dropFirst())
    while !arguments.isEmpty {
        let flag = arguments.removeFirst()
        func value() throws -> String {
            guard !arguments.isEmpty else {
                throw GeneratorError.message("Missing value for \(flag).")
            }
            return arguments.removeFirst()
        }

        switch flag {
        case "--resources":
            resources = URL(
                fileURLWithPath: try value(),
                isDirectory: true
            )
        case "--output":
            output = URL(fileURLWithPath: try value())
        case "-h", "--help":
            print(usage)
            exit(0)
        default:
            throw GeneratorError.message("Unknown argument: \(flag)")
        }
    }

    guard let resources else {
        throw GeneratorError.message("Missing required argument --resources.")
    }
    guard let output else {
        throw GeneratorError.message("Missing required argument --output.")
    }
    return (resources, output)
}

private func readJSON<T: Decodable>(_ type: T.Type, at url: URL) throws -> T {
    let data: Data
    do {
        data = try Data(contentsOf: url)
    } catch {
        throw GeneratorError.message("Cannot read \(url.path): \(error)")
    }

    do {
        return try JSONDecoder().decode(type, from: data)
    } catch {
        throw GeneratorError.message("Cannot decode \(url.path): \(error)")
    }
}

private func readText(at url: URL) throws -> String {
    do {
        return try String(contentsOf: url, encoding: .utf8)
    } catch {
        throw GeneratorError.message("Cannot read \(url.path): \(error)")
    }
}

private func readNonEmptyText(
    for id: String,
    kind: String,
    at url: URL
) throws -> String {
    let text = try readText(at: url)
    guard !text.isEmpty else {
        throw GeneratorError.message(
            "The text for \(kind) \(id) is empty: \(url.path)"
        )
    }
    return text
}

/// Rejects IDs that are empty or shared by more than one entry.
private func validateUniqueIDs(_ ids: [String], kind: String) throws {
    var seen: Set<String> = []
    for id in ids {
        guard !id.isEmpty else {
            throw GeneratorError.message("A \(kind) entry has an empty ID.")
        }
        guard seen.insert(id).inserted else {
            throw GeneratorError.message("Duplicate \(kind) ID: \(id).")
        }
    }
}

/// Rejects empty tokens and tokens that do not occur in `text`.
private func validateTokens(
    of entryID: String,
    in text: String,
    _ tokens: [(kind: String, value: String?)]
) throws {
    for token in tokens {
        guard let value = token.value else {
            continue
        }
        guard !value.isEmpty else {
            throw GeneratorError.message(
                "\(entryID) has an empty \(token.kind)."
            )
        }
        guard text.contains(value) else {
            throw GeneratorError.message(
                "The \(token.kind) for \(entryID) does not appear in its text: "
                    + String(reflecting: value)
            )
        }
    }
}

/// Rejects metadata entries without a text file, and text files without a
/// metadata entry.
private func validateResourceFiles(
    at resources: URL,
    kind: String,
    ids: [String]
) throws {
    let folder = resources.appendingPathComponent(
        kind + "s",
        isDirectory: true
    )
    let files: [URL]
    do {
        files = try FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil
        )
    } catch {
        throw GeneratorError.message("Cannot read \(folder.path): \(error)")
    }

    var fileIDs: [String: String] = [:]
    for file in files where file.pathExtension == "txt" {
        let id = file.deletingPathExtension().lastPathComponent
        if let firstPath = fileIDs[id] {
            throw GeneratorError.message(
                "Duplicate \(kind) text file for \(id): "
                    + "\(firstPath) and \(file.path)"
            )
        }
        fileIDs[id] = file.path
    }

    let metadataIDs = Set(ids)
    let withoutMetadata = Set(fileIDs.keys).subtracting(metadataIDs).sorted()
    if !withoutMetadata.isEmpty {
        throw GeneratorError.message(
            "Missing \(kind) metadata for: "
                + withoutMetadata.joined(separator: ", ")
        )
    }

    let withoutText = metadataIDs.subtracting(fileIDs.keys).sorted()
    if !withoutText.isEmpty {
        throw GeneratorError.message(
            "Missing \(kind) text for: " + withoutText.joined(separator: ", ")
        )
    }
}

/// Rejects exceptions that name licenses the catalog does not contain.
private func validateCompatibleLicenses(
    _ exceptions: [ExceptionEntry],
    licenseIDs: Set<String>
) throws {
    for exception in exceptions {
        for id in exception.with ?? [] {
            guard licenseIDs.contains(id) else {
                throw GeneratorError.message(
                    "\(exception.id) is compatible with an unknown license: "
                        + id
                )
            }
        }
    }
}

private func multiLineLiteral(
    _ value: String,
    indentation: String
) -> String {
    var hashCount = 1
    let hashes: String
    while true {
        let candidate = String(repeating: "#", count: hashCount)
        let terminator = "\"\"\"\(candidate)"
        let interpolationStart = "\\\(candidate)("
        if !value.contains(terminator) && !value.contains(interpolationStart) {
            hashes = candidate
            break
        }
        hashCount += 1
    }

    let lines = value.split(
        separator: "\n",
        omittingEmptySubsequences: false
    )
    let indented =
        lines
        .map { $0.isEmpty ? "" : indentation + $0 }
        .joined(separator: "\n")
    return "\(hashes)\"\"\"\n\(indented)\n\(indentation)\"\"\"\(hashes)"
}

private func quotedLiteral(_ value: String) -> String {
    var result = "\""
    for scalar in value.unicodeScalars {
        switch scalar {
        case "\\":
            result += "\\\\"
        case "\"":
            result += "\\\""
        case "\n":
            result += "\\n"
        case "\r":
            result += "\\r"
        case "\t":
            result += "\\t"
        default:
            if scalar.value < 0x20 || scalar.value == 0x7F {
                result += String(format: "\\u{%X}", scalar.value)
            } else {
                result.unicodeScalars.append(scalar)
            }
        }
    }
    result += "\""
    return result
}

private func optionalLiteral<T>(_ value: T?, transform: (T) -> String) -> String {
    guard let value else {
        return "nil"
    }
    return transform(value)
}

private func arrayLiteral(
    _ values: [String],
    indentation: String
) -> String {
    guard !values.isEmpty else {
        return "[]"
    }

    let itemIndentation = indentation + "    "
    let items = values.map {
        itemIndentation
            + multiLineLiteral($0, indentation: itemIndentation)
    }
    return "[\n\(items.joined(separator: ",\n"))\n\(indentation)]"
}

private func makeOutput(
    licensesJSON: URL,
    exceptionsJSON: URL,
    resources: URL
) throws -> String {
    let licenses = try readJSON([LicenseEntry].self, at: licensesJSON)
        .sorted { $0.id < $1.id }
    let exceptions = try readJSON([ExceptionEntry].self, at: exceptionsJSON)
        .sorted { $0.id < $1.id }

    try validateUniqueIDs(licenses.map(\.id), kind: "license")
    try validateUniqueIDs(exceptions.map(\.id), kind: "exception")
    try validateResourceFiles(
        at: resources,
        kind: "license",
        ids: licenses.map(\.id)
    )
    try validateResourceFiles(
        at: resources,
        kind: "exception",
        ids: exceptions.map(\.id)
    )
    try validateCompatibleLicenses(
        exceptions,
        licenseIDs: Set(licenses.map(\.id))
    )

    var licenseBlocks: [String] = []
    for license in licenses {
        let text = try readNonEmptyText(
            for: license.id,
            kind: "license",
            at: resources.appendingPathComponent("licenses/\(license.id).txt")
        )
        var tokens: [(kind: String, value: String?)] = [
            (kind: "copyright notice", value: license.copyright),
            (kind: "year placeholder", value: license.replace?.year),
            (kind: "name placeholder", value: license.replace?.name),
        ]
        tokens += (license.optional ?? []).map {
            (kind: "optional part", value: $0)
        }
        try validateTokens(of: license.id, in: text, tokens)

        let replacement = optionalLiteral(license.replace) { replace in
            "CopyrightReplacement(yearToken: \(optionalLiteral(replace.year, transform: quotedLiteral)), "
                + "nameToken: \(optionalLiteral(replace.name, transform: quotedLiteral)))"
        }

        var optionalArgument = ""
        if let optional = license.optional {
            optionalArgument =
                ",\n                optionalParts: "
                + arrayLiteral(optional, indentation: "                ")
        }

        licenseBlocks.append(
            """
                        License(
                            id: \(quotedLiteral(license.id)),
                            text: \(multiLineLiteral(text, indentation: "                ")),
                            copyrightReplacement: \(replacement),
                            copyrightNotice: \(optionalLiteral(license.copyright, transform: quotedLiteral))\(optionalArgument)
                        )
            """
        )
    }

    var exceptionBlocks: [String] = []
    for exception in exceptions {
        let text = try readNonEmptyText(
            for: exception.id,
            kind: "exception",
            at: resources.appendingPathComponent(
                "exceptions/\(exception.id).txt"
            )
        )
        let optionalTokens = (exception.optional ?? []).map {
            (kind: "optional part", value: $0)
        }
        try validateTokens(of: exception.id, in: text, optionalTokens)

        let compatible = optionalLiteral(exception.with) { licenses in
            "[" + licenses.map(quotedLiteral).joined(separator: ", ") + "]"
        }

        var optionalArgument = ""
        if let optional = exception.optional {
            optionalArgument =
                ",\n                optionalParts: "
                + arrayLiteral(optional, indentation: "                ")
        }

        exceptionBlocks.append(
            """
                        LicenseException(
                            id: \(quotedLiteral(exception.id)),
                            text: \(multiLineLiteral(text, indentation: "                ")),
                            compatibleLicenses: \(compatible)\(optionalArgument)
                        )
            """
        )
    }

    let licenseList = licenseBlocks.joined(separator: ",\n")
    let exceptionList = exceptionBlocks.joined(separator: ",\n")
    return [
        "// This file is generated by GenerateLicenseCatalog. Do not edit it by hand.",
        "// swift-format-ignore-file",
        "",
        "extension LicenseCatalog {",
        "    static let builtIn = LicenseCatalog(",
        "        licenses: [",
        licenseList,
        "        ],",
        "        exceptions: [",
        exceptionList,
        "        ]",
        "    )",
        "}",
        "",
    ].joined(separator: "\n")
}

private func run() throws {
    let (resources, output) = try parseArguments()
    let licensesJSON = resources.appendingPathComponent("licenses.json")
    let exceptionsJSON = resources.appendingPathComponent("exceptions.json")

    let contents = try makeOutput(
        licensesJSON: licensesJSON,
        exceptionsJSON: exceptionsJSON,
        resources: resources
    )

    do {
        try FileManager.default.createDirectory(
            at: output.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try contents.write(to: output, atomically: true, encoding: .utf8)
    } catch {
        throw GeneratorError.message("Cannot write \(output.path): \(error)")
    }
}

do {
    try run()
} catch {
    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
    exit(1)
}
