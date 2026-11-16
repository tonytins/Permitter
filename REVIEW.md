# Review Guide

Use this checklist when reviewing a change to Permitter. It is adapted from the contributor and review practices in [NVIDIA FLARE's contribution guide](https://github.com/NVIDIA/NVFlare/blob/main/CONTRIBUTING.md), by way of [Hudini](https://github.com/tonytins/Hudini), with checks tailored to this Swift package and CLI. The rules it checks against are in [AGENTS.md](AGENTS.md).

## Before Reviewing

- Read the change description and the relevant code, tests, and fixtures.
- Identify the user-visible behavior the change is meant to address: the text
  on standard output, warnings and errors on standard error, and the exit
  status. If it refers to an issue or to Licensor compatibility, check that the
  change addresses that context.
- Check available build and test results. Run `swift build` and `swift test`
  when the change or its verification warrants it. If `Resources/Licensor`, the
  generator, or `Generated/LicenseCatalogData.swift` changed, run
  `swift Tools/GenerateLicenseCatalog.swift` and confirm the committed catalog
  still matches.
- Run the built binary for behavior the unit tests do not cover: an unknown ID,
  a `WITH` expression, conflicting flags, and `permitter GPL-3.0 | head`.
  Report any check you could not run.

## Review Checklist

- Does the rendered text match the stated intent for every affected license and
  exception, including optional parts, copyright placeholder handling, and the
  trailing newline?
- Are the streams and exit status correct? Rendered text goes to standard
  output, warnings and errors to standard error, invalid input exits non-zero,
  and a closed pipe exits 0.
- Can user input reach a trap? Check `!`, `try!`, `as!`, string indexes and
  slices, integer arithmetic, and `Dictionary(uniqueKeysWithValues:)`.
  Malformed expressions, empty IDs, unknown IDs, and long names must produce an
  error or a defined result.
- Does the generator reject duplicate or empty IDs, missing texts, and
  replacement tokens that do not occur in their text? Is the generated catalog
  still in sync with `Resources/Licensor`?
- Does the unbuffered writer still handle `EINTR`, `EPIPE`, and short writes,
  and can its loop terminate on a zero-byte write?
- Do focused tests cover the changed behavior, with a regression test for each
  fixed crash or malformed-input case? Do existing fixtures need updating?
- Are the README, the `--help` text, and the behavior they describe still
  accurate, and does the CLI remain a drop-in replacement for Licensor?
- Does the change follow Swift 6 language mode, the existing naming and
  `.swift-format`, and avoid unnecessary force unwraps or API changes?

## Writing Review Comments

- Report concrete correctness, stability, compatibility, or missing-test  
  concerns; do not block changes on personal style preferences.
- Make each comment specific, constructive, and actionable. Point to the  
  smallest relevant location and explain the impact and a useful next step.
- Prioritize findings by impact:
  - **Blocking**: prevents the package from building or its tests from  
    passing, or traps, hangs, or truncates output in normal use.
  - **High**: breaks an existing flag, exit status, documented behavior, or  
    Licensor compatibility, or leaves an input boundary unvalidated.
  - **Medium**: causes a limited but meaningful behavior or reliability issue,  
    or leaves docs describing something that isn't true.
  - **Low**: a small edge case or non-blocking improvement.
- If no actionable issues remain, say so and note any important checks that  
  were not run.
