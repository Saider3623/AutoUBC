# AI contribution rules

## Comment language

- Write all code comments and documentation comments in Ukrainian or English only.
- Do not add comments in Russian.
- This rule applies to `//`, `///`, block comments, TODO/FIXME notes, and inline comments in Dart source.
- Preserve Russian, Ukrainian, and English user-facing strings when they are intentional localization or domain data; this rule concerns comments, not product copy.

## Scope discipline

- Reuse the existing Flutter, Provider, Isar, and localization patterns before introducing new dependencies.
- Keep changes focused on the requested behavior and run `flutter analyze` and relevant tests after edits.
