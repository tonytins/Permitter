import Foundation
import Testing

@testable import Permitter

struct LicenseRendererTests {
    private let renderer = LicenseRenderer(currentYear: { 2026 })

    @Test func rendersMIT() throws {
        let result = try render(
            "MIT",
            copyrightHolder: nil,
            keepPlaceholder: false,
            skipOptional: false
        )

        #expect(try result.text == fixture("MIT-default"))
        #expect(result.warning == nil)
    }

    @Test func rendersMITWithCopyrightHolder() throws {
        let result = try render(
            "MIT",
            copyrightHolder: "Tony Bark",
            keepPlaceholder: false,
            skipOptional: false
        )

        #expect(try result.text == fixture("MIT-name"))
        #expect(result.text.contains("Copyright (c) 2026 Tony Bark\n"))
    }

    @Test func rendersMITWithoutOptionalParts() throws {
        let result = try render(
            "MIT",
            copyrightHolder: nil,
            keepPlaceholder: false,
            skipOptional: true
        )

        #expect(try result.text == fixture("MIT-skip-optional"))
    }

    @Test func keepsPlaceholderWhenRequested() throws {
        let result = try render(
            "MIT",
            copyrightHolder: nil,
            keepPlaceholder: true,
            skipOptional: false
        )

        #expect(
            result.text.hasPrefix(
                "MIT License Copyright (c) <year> <copyright holders>\n"
            )
        )
    }

    @Test func keepsCopyrightWhenSkippingOptionalParts() throws {
        let result = try render(
            "MIT",
            copyrightHolder: "Tony Bark",
            keepPlaceholder: false,
            skipOptional: true
        )

        #expect(
            result.text.hasPrefix("Copyright (c) 2026 Tony Bark\n\nPermission")
        )
    }

    @Test func nameHasNoEffectWithoutAReplacement() throws {
        let withName = try render(
            "GPL-3.0",
            copyrightHolder: "Tony Bark",
            keepPlaceholder: false,
            skipOptional: false
        )
        let withoutName = try render(
            "GPL-3.0",
            copyrightHolder: nil,
            keepPlaceholder: false,
            skipOptional: false
        )

        #expect(withName.text == withoutName.text)
    }

    @Test func rendersBSD3ClauseWithoutCopyrightNotice() throws {
        let result = try render(
            "BSD-3-Clause",
            copyrightHolder: nil,
            keepPlaceholder: false,
            skipOptional: false
        )

        #expect(try result.text == fixture("BSD-3-Clause-default"))
    }

    @Test func replacesISCPlaceholders() throws {
        let result = try render(
            "ISC",
            copyrightHolder: "Tony Bark",
            keepPlaceholder: false,
            skipOptional: false
        )

        #expect(try result.text == fixture("ISC-name"))
    }

    @Test func preservesUnicodeLicenseText() throws {
        let result = try render(
            "CDDL-1.1",
            copyrightHolder: nil,
            keepPlaceholder: false,
            skipOptional: false
        )

        #expect(try result.text == fixture("CDDL-1.1-default"))
        #expect(result.text.contains("§ 252.227-7014(a)(1)"))
    }

    @Test func rendersApacheWithLLVMException() throws {
        let result = try render(
            "Apache-2.0 WITH LLVM-exception",
            copyrightHolder: nil,
            keepPlaceholder: false,
            skipOptional: false
        )

        #expect(
            try result.text
                == fixture("Apache-2.0-WITH-LLVM-exception")
        )
        #expect(result.warning == nil)
    }

    @Test func wrapsExceptionToLicenseWidth() throws {
        let result = try render(
            "GPL-3.0 WITH GCC-exception-3.1",
            copyrightHolder: nil,
            keepPlaceholder: false,
            skipOptional: false
        )

        #expect(
            try result.text
                == fixture("GPL-3.0-WITH-GCC-exception-3.1")
        )
        #expect(
            result.text.contains(
                "Everyone is permitted to copy and distribute verbatim copies of this license document, but changing it\nis not allowed."
            )
        )
    }

    @Test func rendersLinuxSyscallNote() throws {
        let result = try render(
            "GPL-2.0 WITH Linux-syscall-note",
            copyrightHolder: nil,
            keepPlaceholder: false,
            skipOptional: false
        )

        #expect(
            try result.text
                == fixture("GPL-2.0-WITH-Linux-syscall-note")
        )
        #expect(result.warning == nil)
    }

    @Test func warnsAboutIncompatibleException() throws {
        let result = try render(
            "GPL-2.0 WITH GCC-exception-3.1",
            copyrightHolder: nil,
            keepPlaceholder: false,
            skipOptional: false
        )

        #expect(result.warning == LicenseRenderer.incompatibleExceptionWarning)
        #expect(result.text.contains("\n\n\nGCC RUNTIME LIBRARY EXCEPTION\n"))
    }

    @Test func reportsSimilarLicenseIDs() {
        let error = renderError("gpl")

        #expect(
            error
                == .invalidLicense(
                    id: "gpl",
                    similarIDs: [
                        "AGPL-3.0",
                        "GPL-2.0",
                        "GPL-3.0",
                        "LGPL-2.1",
                        "LGPL-3.0",
                    ]
                )
        )
        #expect(
            error.description
                == "Invalid license ID.\nSimilar IDs: AGPL-3.0, GPL-2.0, "
                + "GPL-3.0, LGPL-2.1, LGPL-3.0."
        )
    }

    @Test func reportsSimilarExceptionIDs() {
        let error = renderError("Apache-2.0 WITH llvm")

        #expect(
            error
                == .invalidException(
                    id: "llvm",
                    similarIDs: ["LLVM-exception"]
                )
        )
    }

    @Test func reportsInvalidExpression() {
        let error = renderError("Apache-2.0 with LLVM-exception")

        #expect(
            error
                == .invalidExpression(
                    .init(
                        licenseID: "Apache-2.0",
                        exceptionID: "LLVM-exception"
                    )
                )
        )
        #expect(
            error.description
                == "Invalid SPDX expression. Did you mean "
                + "\"Apache-2.0 WITH LLVM-exception\"?"
        )
    }

    private func render(
        _ expression: String,
        copyrightHolder: String?,
        keepPlaceholder: Bool,
        skipOptional: Bool
    ) throws -> RenderedLicense {
        try renderer.render(
            expression: expression,
            copyrightHolder: copyrightHolder,
            keepPlaceholder: keepPlaceholder,
            skipOptional: skipOptional
        )
    }

    private func renderError(_ expression: String) -> LicenseRenderError {
        do {
            _ = try render(
                expression,
                copyrightHolder: nil,
                keepPlaceholder: false,
                skipOptional: false
            )
            Issue.record("Expected \(expression) to fail.")
            return .invalidExpression(nil)
        } catch let error as LicenseRenderError {
            return error
        } catch {
            Issue.record("Unexpected error: \(error)")
            return .invalidExpression(nil)
        }
    }

    private func fixture(_ name: String) throws -> String {
        let url = try #require(
            Bundle.module.url(
                forResource: name,
                withExtension: "txt",
                subdirectory: "Fixtures"
            )
        )
        return try String(contentsOf: url, encoding: .utf8)
    }
}
