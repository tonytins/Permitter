# Vendored license data

This directory holds the data the build-tool plugin compiles into Permitter.

## Licenses

`licenses/*.txt` are the license texts from
[`github/choosealicense.com`](https://github.com/github/choosealicense.com),
the corpus GitHub's `licensee` uses to detect licenses. The files are stored
without the website's YAML front matter and without leading blank lines.

`ChooseALicense.commit` records the upstream commit. To refresh the texts:

```sh
Scripts/vendor-choosealicense.sh
```

The script verifies each file's `spdx-id`, rejects missing or duplicate IDs,
writes body-only files, and fails if upstream no longer has exactly 47
licenses. Update `licenses.json` if the set of IDs changed, then run:

```sh
Scripts/generate-license-list.sh
swift build
swift test
```

`CDDL-1.1.txt` is the one exception: choosealicense.com does not carry it, so
it is the SPDX text copied from Licensor. The update script leaves it alone.

## Metadata

`licenses.json` is maintained for Permitter, not vendored from upstream. It
names the copyright placeholders to replace, the notice to remove when no
holder is given, and the optional parts removed by `--skip-optional`. Every
token and optional part must occur in its text; the generator rejects the
build otherwise.

The GPL family keeps its `<year>` and `<name of author>` appendix sample
unchanged, matching Licensor's behavior: a copyright holder has no effect on
those licenses. `OFL-1.1` uses `[fullname] ([email])` as its name token so a
holder name replaces both placeholders.

When no name is given, the notice is removed only if the name token does not
appear elsewhere in the terms. PostgreSQL and NCSA keep their notice because
their disclaimers also use `[fullname]`.

## Exceptions

`exceptions/*.txt` and `exceptions.json` are the four exceptions shipped with
Licensor 2.1.0, copied from
[`raftario/licensor`](https://github.com/raftario/licensor) at commit
`a7c74793e529667f58c2ea6bfcd0c6c08e9a1ed6`. Their texts are governed by the
licenses they describe.

## Formatting

License text is emitted as published. `GFDL-1.3` therefore keeps the trailing
spaces that are present upstream, and `CDDL-1.1` keeps its SPDX formatting.
Do not run a formatter over these files: their exact shape is the point.

Exception text is the exception (pun intended): the vendored exceptions are
single paragraphs, so Permitter wraps them to 80 columns when it appends one.

## List

`LIST.md` at the package root lists every ID with a link to its SPDX page. It
is generated from this metadata with `Scripts/generate-license-list.sh`. The
catalog test fails while the file is stale, so regenerate it after adding,
removing, or renaming a license or exception.
