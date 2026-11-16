import Foundation

/// The vendored license data bundled with the executable.
///
/// Permitter reads license text from the generated catalog, which is compiled
/// into the binary. Tests use this bundle to check that the catalog still
/// matches the files it was generated from.
enum LicenseResources {
    static var bundle: Bundle { .module }
}
