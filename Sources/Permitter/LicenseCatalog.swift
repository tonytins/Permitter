/// A license and the transformations needed to apply it.
struct License: Sendable {
    let id: String
    let text: String
    let copyrightReplacement: CopyrightReplacement?
    let copyrightNotice: String?
    let optionalParts: [String]

    init(
        id: String,
        text: String,
        copyrightReplacement: CopyrightReplacement? = nil,
        copyrightNotice: String? = nil,
        optionalParts: [String] = []
    ) {
        self.id = id
        self.text = text
        self.copyrightReplacement = copyrightReplacement
        self.copyrightNotice = copyrightNotice
        self.optionalParts = optionalParts
    }
}

/// Placeholders that are replaced with the current year and the copyright holder.
struct CopyrightReplacement: Sendable {
    let yearToken: String?
    let nameToken: String?
}

/// An SPDX license exception.
struct LicenseException: Sendable {
    let id: String
    let text: String
    let compatibleLicenses: [String]?
    let optionalParts: [String]

    init(
        id: String,
        text: String,
        compatibleLicenses: [String]? = nil,
        optionalParts: [String] = []
    ) {
        self.id = id
        self.text = text
        self.compatibleLicenses = compatibleLicenses
        self.optionalParts = optionalParts
    }
}

/// The licenses and exceptions compiled into the executable.
struct LicenseCatalog: Sendable {
    let licenses: [License]
    let exceptions: [LicenseException]

    private let licensesByID: [String: License]
    private let exceptionsByID: [String: LicenseException]

    init(licenses: [License], exceptions: [LicenseException]) {
        self.licenses = licenses
        self.exceptions = exceptions
        self.licensesByID = Dictionary(
            uniqueKeysWithValues: licenses.map { ($0.id, $0) }
        )
        self.exceptionsByID = Dictionary(
            uniqueKeysWithValues: exceptions.map { ($0.id, $0) }
        )
    }

    var licenseIDs: [String] {
        licenses.map(\.id)
    }

    var exceptionIDs: [String] {
        exceptions.map(\.id)
    }

    func license(id: String) -> License? {
        licensesByID[id]
    }

    func exception(id: String) -> LicenseException? {
        exceptionsByID[id]
    }

    /// IDs that contain the given ID, or are contained by it, ignoring case.
    ///
    /// Results keep catalog order so suggestions are stable.
    func similarLicenseIDs(to id: String) -> [String] {
        similarIDs(to: id, among: licenses.map(\.id))
    }

    /// IDs that contain the given ID, or are contained by it, ignoring case.
    ///
    /// Results keep catalog order so suggestions are stable.
    func similarExceptionIDs(to id: String) -> [String] {
        similarIDs(to: id, among: exceptions.map(\.id))
    }

    private func similarIDs(to id: String, among candidates: [String]) -> [String] {
        let loweredID = id.lowercased()
        return candidates.filter { candidate in
            let loweredCandidate = candidate.lowercased()
            if loweredID.isEmpty || loweredCandidate.isEmpty {
                return true
            }
            return loweredID.contains(loweredCandidate)
                || loweredCandidate.contains(loweredID)
        }
    }
}
