import Foundation
import Testing

@testable import Permitter

struct LicenseCatalogTests {
    private let catalog = LicenseCatalog.builtIn

    @Test func listsLicensesInCatalogOrder() {
        #expect(
            catalog.licenseIDs == [
                "AGPL-3.0",
                "Apache-2.0",
                "Artistic-2.0",
                "BSD-2-Clause",
                "BSD-3-Clause",
                "CC0-1.0",
                "CDDL-1.1",
                "EPL-2.0",
                "GPL-2.0",
                "GPL-3.0",
                "ISC",
                "LGPL-2.1",
                "LGPL-3.0",
                "MIT",
                "MPL-2.0",
                "Unlicense",
                "Zlib",
            ]
        )
    }

    @Test func listsExceptionsInCatalogOrder() {
        #expect(
            catalog.exceptionIDs == [
                "GCC-exception-2.0",
                "GCC-exception-3.1",
                "LLVM-exception",
                "Linux-syscall-note",
            ]
        )
    }

    @Test func findsSimilarLicenseIDsIgnoringCase() {
        #expect(catalog.similarLicenseIDs(to: "mit") == ["MIT"])
        #expect(
            catalog.similarLicenseIDs(to: "GPL-3.0")
                == ["AGPL-3.0", "GPL-3.0", "LGPL-3.0"]
        )
    }

    @Test func treatsAnEmptyIDAsSimilarToEverything() {
        #expect(catalog.similarLicenseIDs(to: "") == catalog.licenseIDs)
        #expect(catalog.similarExceptionIDs(to: "") == catalog.exceptionIDs)
    }

    @Test func everyLicenseHasTextAndUniqueID() {
        #expect(Set(catalog.licenseIDs).count == catalog.licenseIDs.count)

        for license in catalog.licenses {
            #expect(!license.text.isEmpty, "\(license.id) has no text")
        }
    }

    @Test func everyExceptionHasTextAndUniqueID() {
        #expect(Set(catalog.exceptionIDs).count == catalog.exceptionIDs.count)

        for exception in catalog.exceptions {
            #expect(!exception.text.isEmpty, "\(exception.id) has no text")
        }
    }

    @Test func generatedCatalogMatchesVendoredResources() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let resources = root.appendingPathComponent("Resources/Licensor")

        let rawLicenses = try decode(
            [RawLicense].self,
            at: resources.appendingPathComponent("licenses.json")
        )
        let rawExceptions = try decode(
            [RawException].self,
            at: resources.appendingPathComponent("exceptions.json")
        )

        #expect(catalog.licenseIDs == rawLicenses.map(\.id))
        #expect(catalog.exceptionIDs == rawExceptions.map(\.id))

        for raw in rawLicenses {
            let license = try #require(catalog.license(id: raw.id))
            let file = resources.appendingPathComponent(
                "licenses/\(raw.id).txt"
            )

            #expect(
                license.text == (try String(contentsOf: file, encoding: .utf8))
            )
            #expect(license.copyrightNotice == raw.copyright)
            #expect(license.optionalParts == (raw.optional ?? []))
            #expect(license.copyrightReplacement?.yearToken == raw.replace?.year)
            #expect(license.copyrightReplacement?.nameToken == raw.replace?.name)
        }

        for raw in rawExceptions {
            let exception = try #require(catalog.exception(id: raw.id))
            let file = resources.appendingPathComponent(
                "exceptions/\(raw.id).txt"
            )

            #expect(
                exception.text == (try String(contentsOf: file, encoding: .utf8))
            )
            #expect(exception.compatibleLicenses == raw.with)
            #expect(exception.optionalParts == (raw.optional ?? []))
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, at url: URL) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }
}

private struct RawLicense: Decodable {
    let id: String
    let replace: RawReplacement?
    let copyright: String?
    let optional: [String]?
}

private struct RawReplacement: Decodable {
    let year: String?
    let name: String?
}

private struct RawException: Decodable {
    let id: String
    let with: [String]?
    let optional: [String]?
}
