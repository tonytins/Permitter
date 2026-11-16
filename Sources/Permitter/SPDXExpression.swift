/// The parts of an SPDX expression that Permitter understands.
struct SPDXExpression: Equatable, Sendable {
    let licenseID: String
    let exceptionID: String?

    /// Parses a bare license ID or a `LICENSE WITH EXCEPTION` expression.
    ///
    /// Inputs are split on single spaces, including empty components, to match
    /// the behavior of Licensor.
    init(parsing rawExpression: String) throws {
        let parts = rawExpression.split(
            separator: " ",
            omittingEmptySubsequences: false
        )

        switch parts.count {
        case 1:
            self.init(licenseID: String(parts[0]), exceptionID: nil)
        case 3 where parts[1] == "WITH":
            self.init(
                licenseID: String(parts[0]),
                exceptionID: String(parts[2])
            )
        case 3:
            throw SPDXExpressionError.invalid(
                suggestion: .init(
                    licenseID: String(parts[0]),
                    exceptionID: String(parts[2])
                )
            )
        default:
            throw SPDXExpressionError.invalid(suggestion: nil)
        }
    }

    private init(licenseID: String, exceptionID: String?) {
        self.licenseID = licenseID
        self.exceptionID = exceptionID
    }
}

enum SPDXExpressionError: Error, Equatable {
    case invalid(suggestion: Suggestion?)

    struct Suggestion: Equatable, Sendable {
        let licenseID: String
        let exceptionID: String
    }
}
