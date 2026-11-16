# Choose A License license data

## Intent

Permitter should emit the same license texts that GitHub uses for license
detection. GitHub detects licenses through `licensee`, and `licensee` vendors
[`github/choosealicense.com`](https://github.com/github/choosealicense.com) as
its matching corpus. Replacing the Licensor/SPDX texts with the
`choosealicense.com` texts — and preserving their formatting instead of
reflowing them — makes the output as close to the detection corpus as a CLI
can get.

The change also adds every license in `choosealicense.com`, not just the ones
Licensor happened to ship.

## Goals

- Use the 47 license texts from `choosealicense.com`, verbatim apart from
  placeholder replacement and optional-part removal.
- Keep the existing CLI: SPDX IDs, `WITH` exceptions, `--licenses`,
  `--exceptions`, `--keep-placeholder`, `--skip-optional`, and broken-pipe
  handling.
- Keep `CDDL-1.1` as the one SPDX fallback so no previously supported ID
  disappears.
- Keep the build offline and reproducible: vendored files are committed, and a
  script refreshes them from a pinned commit.
- Keep the generated catalog and its source files in sync, checked by the
  build and the test suite.

## Non-goals

- Adding exceptions from another source. The 4 Licensor exceptions stay.
- Adding arguments for `[project]`, `[projecturl]`, or `[email]`. Those
  placeholders remain in the texts that contain them.
- Detecting or validating license files on disk.
- Changing the SPDX expression parser or the standard-stream writer.

## Anti-goals

- Reflowing or otherwise rewriting the vendored license texts. That would
  defeat the point of matching the detection corpus.
- Fetching license data at build time or at runtime.
- Letting a vendored file and the catalog drift apart silently.

## Approaches considered

### A. Mirror the upstream tree

Vendor `_licenses/*.txt` with their YAML front matter and parse `spdx-id` in
the build-tool generator.

- Pro: the vendored files are exactly what upstream ships, so provenance is
  obvious and updating is a file copy.
- Con: every build depends on upstream's front-matter shape, and the generator
  and tests need a YAML reader for metadata that is read once.

### B. Strip at vendor time

Pin a commit in an update script. The script fetches the upstream tree,
verifies each file's `spdx-id`, strips the front matter, and writes body-only
files. The generator keeps reading plain text.

- Pro: the generator and the byte-for-byte test stay simple; the script makes
  updates deliberate and repeatable.
- Con: updating requires running the script rather than copying one folder.

**Chosen: B.** The front matter is upstream website metadata, not license
text. Stripping it once is cheaper than teaching the build to parse it.

## Decisions

### Resource layout

```
Sources/Permitter/Resources/LicenseData/
  licenses.json              # metadata authored for Permitter
  exceptions.json            # copied from Licensor
  licenses/<SPDX-ID>.txt     # 47 choosealicense texts + CDDL-1.1
  exceptions/<SPDX-ID>.txt   # 4 Licensor exceptions
  README.md                  # provenance and update instructions
```

`Resources/Licensor` is removed. The build plugin, the package resource copy,
and the catalog test move to `LicenseData`.

### Vendoring

`Scripts/vendor-choosealicense.sh`:

- defaults to the pinned commit recorded in the script;
- clones with a sparse checkout of `_licenses`;
- reads each `spdx-id`, rejects missing or duplicate IDs;
- strips the front matter and any leading blank lines;
- writes body-only files named `<SPDX-ID>.txt`;
- expects 47 files and fails if upstream's count changes;
- leaves extra files alone, so `CDDL-1.1.txt` survives;
- records the commit in `ChooseALicense.commit` for provenance.

The script is run by a maintainer, never by the build.

### Formatting

License text is stored and emitted as published, with only these changes:

- `\r\n` and `\r` become `\n`;
- the copyright placeholder tokens are replaced (or the notice is removed);
- optional parts are removed when `--skip-optional` is used;
- leading and trailing newlines are trimmed, and exactly one trailing newline
  is written.

`LicenseTextFormatter` is deleted, along with its tests. `TextWrapper` stays,
but only for exceptions: the vendored exception texts are single paragraphs,
license detection does not use them, and emitting them unwrapped would produce
lines hundreds of columns wide. Exceptions are wrapped to 80 columns instead
of the old behavior of matching the license's maximum line width. This
intentionally preserves the one trailing-whitespace line in `GFDL-1.3`, and the
raw `CDDL-1.1` text.

### Metadata

`licenses.json` keeps the existing schema:

```json
{
  "id": "MIT",
  "replace": { "year": "[year]", "name": "[fullname]" },
  "copyright": "Copyright (c) [year] [fullname]",
  "optional": ["MIT License\n\n"]
}
```

- `replace` is set only for licenses whose top copyright notice is meant to be
  filled in. The GPL family keeps its `<year>`/`<name of author>` appendix
  sample unchanged, matching Licensor's behavior.
- `copyright` is the notice removed when no holder is given and
  `--keep-placeholder` is false. It is the exact text in the new body,
  including multi-line notices such as NCSA's `Developed by` block. The
  renderer keeps the notice when the name token still appears elsewhere in the
  terms (PostgreSQL's warranty disclaimer, NCSA's non-endorsement clause), so
  removing it cannot leave `[fullname]` behind.
- `optional` strings are exact substrings of the new bodies. They are authored
  for the licenses that had optional parts before (MIT, ISC, Zlib, Unlicense,
  CC0, EPL, EUPL, Artistic, MPL, Apache, GPL/AGPL/LGPL, CDDL). New licenses
  start with no optional parts.
- `OFL-1.1` uses `[fullname] ([email])` as its name token, so a holder name
  replaces both placeholders and does not leave a stray `[email]`.

The generator keeps validating that every token and optional part occurs in
its text, and adds checks that every vendored license file has metadata and
vice versa.

### Catalog order

The generator sorts licenses and exceptions by ID, so `--licenses` and
`--exceptions` are stable and alphabetical. The test compares against the
sorted metadata.

### Tests

- Update the expected catalog to the 48 IDs (47 choosealicense + CDDL-1.1).
- Regenerate the expected-output fixtures from the new bodies.
- Replace `normalizesEveryLicense` with checks that every license renders with
  exactly one trailing newline and that the body matches its vendored file.
- Replace `wrapsExceptionToLicenseWidth` with a check that the exception text
  is wrapped to 80 columns.
- Keep the existing validation, SPDX, and broken-pipe coverage.

### Documentation

Update the README's behavior, license-data, and credits sections; the
`AGENTS.md` project-structure and golden-rule references; and `REVIEW.md`'s
resource and formatting checks.

## What is left to the builder

- Generate the metadata strings from the vendored bodies, then review the
  exact optional-part boundaries.
- Regenerate fixtures deterministically. Year-dependent fixtures are produced
  with the test renderer's fixed year (`2026`), not the wall clock.
- Confirm the CLI by hand: `--licenses`, `--exceptions`, an unknown ID, a
  `WITH` expression, `--skip-optional`, and `permitter GPL-3.0 | head`.
- Decide whether any new license needs an optional part that this design did
  not name. If so, add it with a matching test.
