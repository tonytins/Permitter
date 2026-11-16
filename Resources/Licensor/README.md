# Vendored Licensor data

These files are copied from [raftario/licensor](https://github.com/raftario/licensor)
at commit `a7c74793e529667f58c2ea6bfcd0c6c08e9a1ed6`, which is the license and
exception data shipped with Licensor 2.1.0.

- `licenses.json` and `exceptions.json` contain the metadata Licensor uses to
  apply copyright placeholders and optional parts.
- `licenses/*.txt` and `exceptions/*.txt` are the texts Licensor embeds after
  decompressing its gzipped copies. They are stored uncompressed so diffs stay
  readable.

Licensor takes these texts from the [SPDX License List](https://spdx.org/licenses/).
Each license text is governed by the license it describes; the metadata was
published by the Licensor project under its MIT license.

Do not edit these files by hand. Replace them with fresh copies from Licensor,
then run:

```sh
swift Tools/GenerateLicenseCatalog.swift
swift test
```
