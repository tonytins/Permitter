import ArgumentParser
import Testing

@testable import Permitter

struct PermitterCommandTests {
    @Test func parsesLicenseAndCopyrightHolder() throws {
        let command = try parse(["MIT", "Tony Bark"])

        #expect(command.spdxExpression == "MIT")
        #expect(command.copyrightHolder == "Tony Bark")
        #expect(!command.licenses)
        #expect(!command.exceptions)
    }

    @Test func parsesShortFlags() throws {
        let command = try parse(["-p", "-o", "MIT"])

        #expect(command.keepPlaceholder)
        #expect(command.skipOptional)
    }

    @Test func parsesLongFlags() throws {
        let command = try parse([
            "--keep-placeholder",
            "--skip-optional",
            "MIT",
        ])

        #expect(command.keepPlaceholder)
        #expect(command.skipOptional)
    }

    @Test func parsesListingFlags() throws {
        #expect(try parse(["-l"]).licenses)
        #expect(try parse(["--licenses"]).licenses)
        #expect(try parse(["-e"]).exceptions)
        #expect(try parse(["--exceptions"]).exceptions)
    }

    @Test func parsesVersionFlag() throws {
        #expect(try parse(["-V"]).showVersion)
        #expect(try parse(["--version"]).showVersion)
    }

    private func parse(_ arguments: [String]) throws -> Permitter {
        let command = try Permitter.parseAsRoot(arguments)
        return try #require(command as? Permitter)
    }
}
