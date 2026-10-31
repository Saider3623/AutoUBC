# AI contribution rules

## Comment language

- Write all code comments and documentation comments in Ukrainian or English only.
- This rule applies to `//`, `///`, block comments, TODO/FIXME notes, and inline comments in Dart source.
- The app is localized into Ukrainian (default) and English only; add every new user-facing string to both ARB files.

## Scope discipline

- Reuse the existing Flutter, Provider, Isar, and localization patterns before introducing new dependencies.
- Keep changes focused on the requested behavior and run `flutter analyze` and relevant tests after edits.
