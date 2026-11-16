import ArgumentParser

@main
struct Permitter: ParsableCommand {
    static func main() {
        // A closed output pipe should become EPIPE and exit successfully instead
        // of terminating the process with SIGPIPE.
        StandardStream.ignoreBrokenPipeSignal()
        Self.main(nil)
    }

    static let semanticVersion = "0.1.0"

    static let configuration = CommandConfiguration(
        commandName: "permitter",
        abstract: "Write licenses to standard output.",
        discussion: """
            Write a license to standard output given an SPDX expression. A name
            for the copyright holder can optionally be provided for licenses
            where a notice is included. If the provided ID isn't found, similar
            ones will be suggested. Licenses are all compiled into the binary.
            """
    )

    @Flag(
        name: [.customShort("V"), .customLong("version")],
        help: "Prints version information."
    )
    var showVersion = false

    @Flag(
        name: [.customShort("l"), .customLong("licenses")],
        help: "Lists available licenses."
    )
    var licenses = false

    @Flag(
        name: [.customShort("e"), .customLong("exceptions")],
        help: "Lists available exceptions."
    )
    var exceptions = false

    @Flag(
        name: [.customShort("p"), .customLong("keep-placeholder")],
        help: "Keeps the copyright notice even if no name is specified."
    )
    var keepPlaceholder = false

    @Flag(
        name: [.customShort("o"), .customLong("skip-optional")],
        help: "Skips optional license contents."
    )
    var skipOptional = false

    @Argument(
        help: ArgumentHelp(
            "SPDX license ID or expression.",
            discussion: """
                WITH expressions are supported, i.e. "Apache-2.0 WITH \
                LLVM-exception", just make sure to surround them with quotes.
                """
        )
    )
    var spdxExpression: String?

    @Argument(
        help: ArgumentHelp(
            "Name of the copyright holder.",
            discussion: """
                Will be used in the copyright notice in licenses where it is \
                present. Has no effect if the license has no copyright notice.
                """
        )
    )
    var copyrightHolder: String?

    mutating func run() throws {
        if showVersion {
            try write("permitter \(Self.semanticVersion)\n")
            return
        }

        let catalog = LicenseCatalog.builtIn

        if licenses || exceptions {
            try rejectConflictingListingArguments()
            let ids = licenses ? catalog.licenseIDs : catalog.exceptionIDs
            try write(ids.isEmpty ? "" : ids.joined(separator: "\n") + "\n")
            return
        }

        guard let spdxExpression else {
            try failUsage(
                "The following required arguments were not provided:\n"
                    + "    <--licenses|--exceptions|LICENSE>"
            )
        }

        let renderer = LicenseRenderer(catalog: catalog)
        let rendered: RenderedLicense
        do {
            rendered = try renderer.render(
                expression: spdxExpression,
                copyrightHolder: copyrightHolder,
                keepPlaceholder: keepPlaceholder,
                skipOptional: skipOptional
            )
        } catch let error as LicenseRenderError {
            try writeToStandardError(error.description + "\n")
            throw ExitCode.failure
        }

        try write(rendered.text)

        if let warning = rendered.warning {
            try writeToStandardError(warning + "\n")
        }
    }

    private func rejectConflictingListingArguments() throws {
        if licenses && exceptions {
            try failUsage(
                "The argument '--licenses' cannot be used with '--exceptions'."
            )
        }

        guard spdxExpression != nil else {
            return
        }

        let listFlag = licenses ? "--licenses" : "--exceptions"
        try failUsage(
            "The argument '\(listFlag)' cannot be used with '<LICENSE>'."
        )
    }

    private func failUsage(_ message: String) throws -> Never {
        let usage = """
            error: \(message)

            USAGE:
                permitter [FLAGS] <--licenses|--exceptions|LICENSE> [LICENSE]

            For more information try --help

            """
        try writeToStandardError(usage)
        throw ExitCode.failure
    }

    private func write(_ text: String) throws {
        switch StandardStream.writeToStandardOutput(text) {
        case .success:
            return
        case .brokenPipe:
            throw ExitCode.success
        case .failure:
            throw ExitCode.failure
        }
    }

    private func writeToStandardError(_ text: String) throws {
        switch StandardStream.writeToStandardError(text) {
        case .success:
            return
        case .brokenPipe:
            throw ExitCode.success
        case .failure:
            throw ExitCode.failure
        }
    }
}
