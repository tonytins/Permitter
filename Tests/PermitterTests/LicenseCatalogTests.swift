import Foundation
import Testing

@testable import Permitter

struct LicenseCatalogTests {
    private let catalog = LicenseCatalog.builtIn

    @Test func listsLicensesAlphabetically() {
        #expect(
            catalog.licenseIDs == [
                "0BSD",
                "AFL-3.0",
                "AGPL-3.0",
                "Apache-2.0",
                "Artistic-2.0",
                "BSD-2-Clause",
                "BSD-2-Clause-Patent",
                "BSD-3-Clause",
                "BSD-3-Clause-Clear",
                "BSD-4-Clause",
                "BSL-1.0",
                "BlueOak-1.0.0",
                "CC-BY-4.0",
                "CC-BY-SA-4.0",
                "CC0-1.0",
                "CDDL-1.1",
                "CECILL-2.1",
                "CERN-OHL-P-2.0",
                "CERN-OHL-S-2.0",
                "CERN-OHL-W-2.0",
                "ECL-2.0",
                "EPL-1.0",
                "EPL-2.0",
                "EUPL-1.1",
                "EUPL-1.2",
                "GFDL-1.3",
                "GPL-2.0",
                "GPL-3.0",
                "ISC",
                "LGPL-2.1",
                "LGPL-3.0",
                "LPPL-1.3c",
                "MIT",
                "MIT-0",
                "MPL-2.0",
                "MS-PL",
                "MS-RL",
                "MulanPSL-2.0",
                "NCSA",
                "ODbL-1.0",
                "OFL-1.1",
                "OSL-3.0",
                "PostgreSQL",
                "UPL-1.0",
                "Unlicense",
                "Vim",
                "WTFPL",
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
        #expect(catalog.similarLicenseIDs(to: "mit") == ["MIT", "MIT-0"])
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
        let resources = try #require(
            LicenseResources.bundle.url(
                forResource: "LicenseData",
                withExtension: nil
            )
        )

        let rawLicenses = try decode(
            [RawLicense].self,
            at: resources.appendingPathComponent("licenses.json")
        )
        let rawExceptions = try decode(
            [RawException].self,
            at: resources.appendingPathComponent("exceptions.json")
        )

        #expect(catalog.licenseIDs == rawLicenses.map(\.id).sorted())
        #expect(catalog.exceptionIDs == rawExceptions.map(\.id).sorted())

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
