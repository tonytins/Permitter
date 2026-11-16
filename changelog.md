# Permitter Changelog

## 0.1.111

- **Every license Choose A License carries.** Permitter now ships the 47 texts
  from [choosealicense.com](https://github.com/github/choosealicense.com), the
  corpus GitHub's `licensee` uses to detect licenses, plus the SPDX
  `CDDL-1.1` text. That replaces Licensor's 17 texts, adding IDs such as
  `BSD-4-Clause`, `CERN-OHL-S-2.0`, `GFDL-1.3`, `OFL-1.1`, `PostgreSQL`, and
  `WTFPL`.
- **License text is written as published.** The old formatter removed trailing
  whitespace and wrapped prose to 80 columns, which pulled the text away from
  what detection matches. Now only placeholders, optional parts, and the final
  newline change. Exception text is still wrapped, to 80 columns.
- **A copyright notice that cannot be removed cleanly stays.** With no name and
  no `--keep-placeholder`, the notice is removed, except in PostgreSQL and
  NCSA: their terms also use `[fullname]`, so removal would leave a
  half-filled token behind. Those two print the notice instead.
- **`--licenses` and `--exceptions` are alphabetical.** Both lists are sorted
  by ID, so their order no longer depends on how the data files are stored.
- **`LIST.md` lists every ID.** Each license and exception links to its SPDX
  page, and the file is generated from the same metadata the binary uses.

For developers: license data lives under
`Sources/Permitter/Resources/LicenseData`. Refresh the texts with
`Scripts/vendor-choosealicense.sh`, regenerate the list with
`Scripts/generate-license-list.sh`, then run `swift build` and `swift test`.
The generator rejects missing or duplicate IDs, metadata without a text file
(or the reverse), and placeholders or optional parts that no longer occur in
their text. A test fails when `LIST.md` drifts from the catalog.

## 0.1.102

- **License titles sit on their own line.** The MIT, Zlib, and ISC texts now
  put the title and copyright notice on separate lines, as current SPDX texts
  do, instead of relying on a formatter heuristic. Removing a copyright notice
  also removes the blank line after it, so no gap is left behind.

## 0.1.100

Permitter is a Swift rewrite of Licensor, with the same arguments, listings,
diagnostics, and exit statuses. License and exception texts are compiled into
the executable, so no data files are needed at runtime.

- **18 licenses and 4 exceptions**, from Licensor 2.1.0 and the SPDX License
  List, including EUPL-1.2, which Licensor never shipped.
- **`WITH` expressions** combine a license with an exception. When the
  exception is not designed for that license, the license is still written, a
  warning goes to standard error, and the exit status is 0.
- **`--licenses`, `--exceptions`, `--keep-placeholder`, and
  `--skip-optional`** keep Licensor's behavior.
- **`--version`** reports a version derived from Git.
- **Broken pipes are success**, so `permitter GPL-3.0 | head` exits cleanly.
- **`install.sh`** copies a release build into `~/.local/bin`.
- **License text is normalized** before it is written: trailing whitespace is
  removed, prose is wrapped to 80 columns, and a copyright notice that shares
  a line with the license title is moved onto its own line.

For developers: the data was vendored from Licensor 2.1.0 and the SPDX License
List, and a generator compiled it into the executable.
