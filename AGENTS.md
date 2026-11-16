# Project Guidelines

Permitter is a CLI program that print licenses or output them to files. It serves as a drop-in replacement for [Licensor](https://github.com/raftario/licensor), and is named after a discontinued [fork]([https://crates.io/crates/permitter](https://crates.io/crates/permitter)) the maintainer formally used.

## Project Structure

| Path                                                | Contents                                         |
| --------------------------------------------------- | ------------------------------------------------ |
| `Sources/Permitter/Permitter.swift`                 | Command-line interface.                          |
| `Sources/Permitter/SPDXExpression.swift`            | SPDX expression parsing.                         |
| `Sources/Permitter/LicenseRenderer.swift`           | License and exception rendering.                 |
| `Sources/Permitter/LicenseTextFormatter.swift`      | Whitespace cleanup and text reflow.              |
| `Sources/Permitter/TextWrapper.swift`               | Port of `textwrap::fill` for exception wrapping. |
| `Sources/Permitter/LicenseCatalog.swift`            | Catalog types and lookups.                       |
| `Sources/Permitter/StandardStream.swift`            | Unbuffered standard stream writes.               |
| `Sources/Permitter/LicenseResources.swift`          | Bundle access for the vendored license data.     |
| `Sources/Permitter/Resources/Licensor/`             | Vendored Licensor metadata and texts.            |
| `Sources/GenerateLicenseCatalog/main.swift`         | Catalog generator run by the build plugin.       |
| `Plugins/GenerateLicenseCatalogPlugin/plugin.swift` | Build-tool plugin that generates the catalog.    |

## Golden Rules

### Design Process

- **Iterate**. A first design or name is a draft. Rebuild clumsy parts as understanding improves.
- **Ask when a decision is open**, and explain the reasoning behind what you suggest.
- **Keep it simple**. The simplest approach that matches what the program does wins.
- **Say what you're unsure of**: assumptions, unverified behaviour, and what needs testing.

### Never Crash (Outranks Feature Work)

Permitter is a filter: it writes license text into pipes and files, so a trap
leaves the user with a truncated `LICENSE` and no explanation. Stability
outranks features.

- **Treat any trap as a crash**: force unwrapping (`!`), `try!`, `as!`, an
  out-of-range index or slice, an integer overflow, a failed `precondition`,
  `fatalError`, or a duplicate key passed to `Dictionary(uniqueKeysWithValues:)`.
  None of them may depend on user input or on catalog data.
- **Report failures explicitly** on standard error and exit non-zero. The only
  successful exits without license text are `--licenses`, `--exceptions`,
  `--version`, `--help`, and a closed output pipe. Never report success for
  text that was skipped or truncated.
- **Validate everything that crosses the process boundary**: the SPDX
  expression, the license and exception IDs, and the copyright-holder name.
  Empty components, malformed `WITH` expressions, and unknown IDs are
  `LicenseRenderError` values, not preconditions.
- **Keep the catalog safe by construction**. The generator must reject
  duplicate or empty IDs, missing texts, and replacement tokens that never
  appear in their text. The catalog is generated from the vendored files during
  every build; edit those files instead of any generated output.
- **Treat standard output as a pipe that can close at any time**. Keep the
  unbuffered writer handling `EINTR`, `EPIPE`, and short writes, and make sure
  its loop cannot spin forever on a zero-byte write. Do not restore the default
  `SIGPIPE` behavior or buffered printing.
- **Prefer `guard let`, failable lookups, and thrown errors** over assertions.
  Assertions belong in tests, not in shipped behavior.
- **Add a focused regression test** for every crash, malformed-input, or
  broken-pipe fix.

## Personal Configuration

Keep personal preferences and machine-specific guidance in git-ignored `*.local` files or directories (such as `AGENTS.local.md`), rather than in shared project instructions. Check for relevant local guidance before environment-specific work. You can create or update these files for details such as:

- Coding preferences
- Local build and development environment
- Personal shortcuts or workflows