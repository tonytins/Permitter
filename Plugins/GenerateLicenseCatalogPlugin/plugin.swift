import Foundation
import PackagePlugin

@main
struct GenerateLicenseCatalogPlugin: BuildToolPlugin {
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) async throws -> [Command] {
        let tool = try context.tool(named: "GenerateLicenseCatalog")
        let resources = context.package.directoryURL.appendingPathComponent(
            "Sources/Permitter/Resources/LicenseData",
            isDirectory: true
        )
        let output = context.pluginWorkDirectoryURL.appendingPathComponent(
            "LicenseCatalogData.swift"
        )

        return [
            .buildCommand(
                displayName: "Generating the license catalog for \(target.name)",
                executable: tool.url,
                arguments: [
                    "--resources",
                    resources.path,
                    "--output",
                    output.path,
                ],
                inputFiles: inputFiles(in: resources),
                outputFiles: [output]
            )
        ]
    }

    /// Lists every vendored file whose contents affect the generated catalog.
    private func inputFiles(in directory: URL) -> [URL] {
        var files = [
            directory.appendingPathComponent("licenses.json"),
            directory.appendingPathComponent("exceptions.json"),
        ]

        for name in ["licenses", "exceptions"] {
            let folder = directory.appendingPathComponent(
                name,
                isDirectory: true
            )
            let contents =
                (try? FileManager.default.contentsOfDirectory(
                    at: folder,
                    includingPropertiesForKeys: nil
                )) ?? []
            files.append(contentsOf: contents.filter { $0.pathExtension == "txt" })
        }

        return files.sorted { $0.path < $1.path }
    }
}
