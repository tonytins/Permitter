import Testing

@testable import Permitter

struct SPDXExpressionTests {
    @Test func parsesBareLicense() throws {
        let expression = try SPDXExpression(parsing: "MIT")

        #expect(expression.licenseID == "MIT")
        #expect(expression.exceptionID == nil)
    }

    @Test func parsesLicenseWithException() throws {
        let expression = try SPDXExpression(
            parsing: "Apache-2.0 WITH LLVM-exception"
        )

        #expect(expression.licenseID == "Apache-2.0")
        #expect(expression.exceptionID == "LLVM-exception")
    }

    @Test func suggestsWithWhenSeparatorIsWrong() {
        #expect(
            throws: SPDXExpressionError.invalid(
                suggestion: .init(
                    licenseID: "Apache-2.0",
                    exceptionID: "LLVM-exception"
                )
            )
        ) {
            try SPDXExpression(parsing: "Apache-2.0 with LLVM-exception")
        }
    }

    @Test func rejectsTwoParts() {
        #expect(throws: SPDXExpressionError.invalid(suggestion: nil)) {
            try SPDXExpression(parsing: "MIT extra")
        }
    }

    @Test func rejectsMoreThanThreeParts() {
        #expect(throws: SPDXExpressionError.invalid(suggestion: nil)) {
            try SPDXExpression(parsing: "MIT WITH LLVM-exception extra")
        }
    }

    @Test func emptyInputBecomesAnEmptyLicenseID() throws {
        let expression = try SPDXExpression(parsing: "")

        #expect(expression.licenseID == "")
        #expect(expression.exceptionID == nil)
    }

    @Test func emptyPartsArePreserved() throws {
        let expression = try SPDXExpression(parsing: " WITH MIT")

        #expect(expression.licenseID == "")
        #expect(expression.exceptionID == "MIT")
    }
}
