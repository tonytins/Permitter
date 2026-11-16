import Foundation

/// The text to write to standard output and any warning to write to standard
/// error after it.
struct RenderedLicense: Equatable, Sendable {
    let text: String
    let warning: String?
}

enum LicenseRenderError: Error, Equatable, Sendable {
    case invalidExpression(SPDXExpressionError.Suggestion?)
    case invalidLicense(id: String, similarIDs: [String])
    case invalidException(id: String, similarIDs: [String])
}

extension LicenseRenderError: CustomStringConvertible {
    var description: String {
        switch self {
        case .invalidExpression(let suggestion):
            guard let suggestion else {
                return "Invalid SPDX expression."
            }
            return "Invalid SPDX expression. Did you mean "
                + "\"\(suggestion.licenseID) WITH \(suggestion.exceptionID)\"?"
        case .invalidLicense(_, let similarIDs):
            return message(
                "Invalid license ID.",
                similarIDs: similarIDs
            )
        case .invalidException(_, let similarIDs):
            return message(
                "Invalid exception ID.",
                similarIDs: similarIDs
            )
        }
    }

    private func message(_ firstLine: String, similarIDs: [String]) -> String {
        guard !similarIDs.isEmpty else {
            return firstLine
        }
        return "\(firstLine)\nSimilar IDs: \(similarIDs.joined(separator: ", "))."
    }
}

struct LicenseRenderer: Sendable {
    static let incompatibleExceptionWarning =
        "This exception wasn't designed to be used with this license. "
        + "Please consider using another license or removing it."

    let catalog: LicenseCatalog
    private let currentYear: @Sendable () -> Int

    init(
        catalog: LicenseCatalog = .builtIn,
        currentYear: @escaping @Sendable () -> Int = LicenseRenderer.utcCurrentYear
    ) {
        self.catalog = catalog
        self.currentYear = currentYear
    }

    func render(
        expression rawExpression: String,
        copyrightHolder: String?,
        keepPlaceholder: Bool,
        skipOptional: Bool
    ) throws -> RenderedLicense {
        let expression: SPDXExpression
        do {
            expression = try SPDXExpression(parsing: rawExpression)
        } catch let error as SPDXExpressionError {
            switch error {
            case .invalid(let suggestion):
                throw LicenseRenderError.invalidExpression(suggestion)
            }
        }

        guard let license = catalog.license(id: expression.licenseID) else {
            throw LicenseRenderError.invalidLicense(
                id: expression.licenseID,
                similarIDs: catalog.similarLicenseIDs(to: expression.licenseID)
            )
        }

        var text = license.text.replacingOccurrences(of: "\r", with: "")

        if let copyrightHolder {
            if let replacement = license.copyrightReplacement {
                if let yearToken = replacement.yearToken {
                    text = text.replacingOccurrences(
                        of: yearToken,
                        with: String(currentYear())
                    )
                }
                if let nameToken = replacement.nameToken {
                    text = text.replacingOccurrences(
                        of: nameToken,
                        with: copyrightHolder
                    )
                }
            }
        } else if !keepPlaceholder, let copyrightNotice = license.copyrightNotice {
            text = removing(copyrightNotice, from: text)
        }

        if skipOptional {
            text = remove(license.optionalParts, from: text)
        }

        text = LicenseTextFormatter.format(text)

        var warning: String?
        if let exceptionID = expression.exceptionID {
            guard let exception = catalog.exception(id: exceptionID) else {
                throw LicenseRenderError.invalidException(
                    id: exceptionID,
                    similarIDs: catalog.similarExceptionIDs(to: exceptionID)
                )
            }

            if let compatibleLicenses = exception.compatibleLicenses,
                !compatibleLicenses.contains(expression.licenseID)
            {
                warning = Self.incompatibleExceptionWarning
            }

            var exceptionText = exception.text.replacingOccurrences(
                of: "\r",
                with: ""
            )
            if skipOptional {
                exceptionText = remove(exception.optionalParts, from: exceptionText)
            }

            let maximumLineLength = max(
                40,
                text.split(
                    separator: "\n",
                    omittingEmptySubsequences: false
                ).map(\.utf8.count).max() ?? 0
            )
            exceptionText = TextWrapper.fill(
                exceptionText,
                width: maximumLineLength
            )
            exceptionText = exceptionText.removingSurroundingNewlines()

            text += "\n\n\n" + exceptionText
        }

        text += "\n"
        return RenderedLicense(text: text, warning: warning)
    }

    private func remove(_ parts: [String], from text: String) -> String {
        parts.reduce(text) { result, part in
            result.replacingOccurrences(of: part, with: "")
        }
    }

    /// Removes the copyright notice together with the blank line that follows
    /// it, so removing a whole line does not leave a gap behind.
    private func removing(_ copyrightNotice: String, from text: String) -> String {
        let noticeAndGap = copyrightNotice + "\n\n"
        if text.contains(noticeAndGap) {
            return text.replacingOccurrences(of: noticeAndGap, with: "")
        }
        return text.replacingOccurrences(of: copyrightNotice, with: "")
    }

    private static func utcCurrentYear() -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar.component(.year, from: Date())
    }
}

extension String {
    /// Removes newline characters from both ends, leaving spaces untouched.
    func removingSurroundingNewlines() -> String {
        var lowerBound = startIndex
        while lowerBound < endIndex, self[lowerBound] == "\n" {
            lowerBound = index(after: lowerBound)
        }

        var upperBound = endIndex
        while upperBound > lowerBound {
            let previous = index(before: upperBound)
            guard self[previous] == "\n" else {
                break
            }
            upperBound = previous
        }

        return String(self[lowerBound..<upperBound])
    }
}
