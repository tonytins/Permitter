# Permitter

A drop-in replacement for [Licensor](https://github.com/raftario/licensor)
written in Swift. It has the same arguments and writes SPDX license texts to
standard output, using the data from Licensor 2.1.0 plus EUPL-1.2. License text
is normalized to remove trailing whitespace, put copyright notices on their own
line, and wrap prose consistently.

## Usage

Write the MIT license with a copyright notice to `LICENSE`:

```sh
permitter MIT "Tony Bark" > LICENSE
```

Write the Apache 2.0 license with the LLVM exception, skipping optional parts:

```sh
permitter "Apache-2.0 WITH LLVM-exception" --skip-optional > LICENSE
```

Print the BSD 3-Clause license without a copyright notice:

```sh
permitter BSD-3-Clause
```

List available licenses or exceptions:

```sh
permitter --licenses
permitter --exceptions
```

### Arguments and flags

| Argument or flag | Description |
| --- | --- |
| `LICENSE` | SPDX license ID or `LICENSE WITH EXCEPTION` expression. |
| `NAME` | Copyright holder. Used only by licenses that contain a copyright notice. |
| `-V`, `--version` | Print version information. |
| `-l`, `--licenses` | List available licenses. |
| `-e`, `--exceptions` | List available exceptions. |
| `-p`, `--keep-placeholder` | Keep the copyright notice when no name is given. |
| `-o`, `--skip-optional` | Remove optional parts of the license and exception. |

Exactly one of `LICENSE`, `--licenses`, or `--exceptions` is required. The
copyright notice is removed when no name is given, unless
`--keep-placeholder` is used. A name has no effect on licenses without a
copyright notice.

## Behavior and compatibility

- All license and exception texts are compiled into the executable.
- `WITH` expressions are supported. Wrap them in quotes so the shell passes
  the whole expression as one argument.
- IDs are case-sensitive. An unknown ID prints similar IDs to standard error
  and exits with status 1.
- When an exception is not designed for the selected license, the license is
  still written, a warning is printed to standard error, and the exit status
  is 0.
- Broken pipes are treated as success, so commands such as
  `permitter GPL-3.0 | head` exit cleanly.
- License text is normalized before it is written: trailing whitespace is
  removed, prose is wrapped to 80 columns, and a copyright notice that shares
  a line with the license title is moved onto its own line.
- The help and version text name this command and differ from Licensor's,
  as do usage errors from the argument parser. License selection, listings,
  license and exception diagnostics, and exit statuses match Licensor 2.1.0;
  whitespace and wrapping intentionally do not.

Permitter currently supports Linux and macOS. Windows support is not
implemented.

## Building

```sh
swift build -c release
```

The executable is `.build/release/permitter`. Copy it somewhere on `PATH`:

```sh
install -m 755 .build/release/permitter ~/.local/bin/permitter
```

## License data

The source data under `Resources/Licensor` is vendored from Licensor 2.1.0,
which in turn takes its texts from the SPDX License List. EUPL-1.2 is not part
of Licensor's catalog; its text was added from the SPDX License List. Each text
belongs to the license it describes.

The renderer normalizes whitespace and wrapping at runtime, so the vendored
texts keep their upstream line breaks. The generated catalog stores them
verbatim.

`Sources/Permitter/Generated/LicenseCatalogData.swift` is generated and
committed so a normal build does not need the generator. After changing the
JSON metadata or text files, regenerate it:

```sh
swift Tools/GenerateLicenseCatalog.swift
```

The generator accepts `--resources PATH` and `--output PATH` if the defaults
do not fit. The test suite verifies that the generated catalog still matches
the vendored files byte for byte.

## Development

```sh
swift test
```

The text wrapper was checked against Licensor 2.1.0. Full-output fixtures
capture Permitter's normalized output, which intentionally differs in
whitespace and wrapping. Fixtures under `Tests/PermitterTests/Fixtures` use the
year 2026; renderer tests inject that year so they do not change over time.

### Layout

| Path | Contents |
| --- | --- |
| `Sources/Permitter/Permitter.swift` | Command-line interface. |
| `Sources/Permitter/SPDXExpression.swift` | SPDX expression parsing. |
| `Sources/Permitter/LicenseRenderer.swift` | License and exception rendering. |
| `Sources/Permitter/LicenseTextFormatter.swift` | Whitespace cleanup and text reflow. |
| `Sources/Permitter/TextWrapper.swift` | Port of `textwrap::fill` for exception wrapping. |
| `Sources/Permitter/LicenseCatalog.swift` | Catalog types and lookups. |
| `Sources/Permitter/StandardStream.swift` | Unbuffered standard stream writes. |
| `Sources/Permitter/Generated/` | Generated catalog data. |
| `Tools/GenerateLicenseCatalog.swift` | Catalog generator. |
| `Resources/Licensor/` | Vendored Licensor metadata and texts. |

## Credits

Permitter follows the behavior of
[Licensor](https://github.com/raftario/licensor) by Raphaël Thériault and
uses license texts from the [SPDX License List](https://spdx.org/licenses/).

## License

Permitter is licensed under the GNU General Public License v3.0. See
[`LICENSE`](LICENSE) for the full text.

The vendored license and exception texts under `Resources/Licensor` belong to
the licenses they describe.
