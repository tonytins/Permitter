# Permitter

A drop-in replacement for [Licensor](https://github.com/raftario/licensor) written in Swift.

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

### Arguments and Flags

| Argument or flag | Description |
| --- | --- |
| `LICENSE` | SPDX license ID or `LICENSE WITH EXCEPTION` expression. |
| `NAME` | Copyright holder. Used only by licenses that contain a copyright notice. |
| `-V`, `--version` | Print version information. |
| `-l`, `--licenses` | List available licenses. |
| `-e`, `--exceptions` | List available exceptions. |
| `-p`, `--keep-placeholder` | Keep the copyright notice when no name is given. |
| `-o`, `--skip-optional` | Remove optional parts of the license and exception. |

Exactly one of `LICENSE`, `--licenses`, or `--exceptions` is required. The copyright notice is removed when no name is given, unless `--keep-placeholder` is used. A name has no effect on licenses without a copyright notice.

## Behaviour and Compatibility

- All license and exception texts are compiled into the executable.
- `WITH` expressions are supported. Wrap them in quotes so the shell passes the whole expression as one argument.
- IDs are case-sensitive. An unknown ID prints similar IDs to standard error and exits with status 1.
- When an exception is not designed for the selected license, the license is still written, a warning is printed to standard error, and the exit status is 0.
- Broken pipes are treated as success, so commands such as `permitter GPL-3.0 | head` exit cleanly.
- License text is normalized before it is written: trailing whitespace is removed, prose is wrapped to 80 columns, and a copyright notice that shares a line with the license title is moved onto its own line.

Permitter currently supports Linux and macOS. Windows support is not implemented.

## Building

```sh
swift build -c release
```

To install to your local ``bin`` directory:

```sh
./install.sh
```

## License Data

The source data under `Resources/Licensor` was vendored from Licensor 2.1.0 and the SPDX License List.

`Sources/Permitter/Generated/LicenseCatalogData.swift` is generated and committed so a normal build does not need the generator. After changing the JSON metadata or text files, regenerate it:

```sh
swift Tools/GenerateLicenseCatalog.swift
```

The generator accepts `--resources PATH` and `--output PATH` if the defaults do not fit. The test suite verifies that the generated catalog still matches the vendored files byte for byte.

## Background

Licensor hasn't been updated since 2023 and their last release is even older, 2019. There was an old fork named [Permitter]([https://crates.io/crates/permitter](https://crates.io/crates/permitter)) that I used, but has since vanished from GitHub apart from my own copy, which is why this rewrite is named after it.

## Credits

Permitter follows the behavior of [Licensor](https://github.com/raftario/licensor) by Raphaël Thériault and uses license texts from the [SPDX License List](https://spdx.org/licenses/).

## License

I license this project under the GPL-3.0 license - see [LICENSE](LICENSE) for details.
