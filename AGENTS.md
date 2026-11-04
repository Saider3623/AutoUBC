# AI contribution rules

## Comment language

- Write all code comments and documentation comments in Ukrainian or English only.
- This rule applies to `//`, `///`, block comments, TODO/FIXME notes, and inline comments in Dart source.
- The app is localized into Ukrainian (default) and English only; add every new user-facing string to both ARB files.

## Interface language

- Support Ukrainian and English in the interface; the language selector must offer only these two languages.
- Use Ukrainian when no language has been selected, the saved language is unsupported, or a screen has no language selection. Do not inherit the device language as the default.

## Scope discipline

- Reuse the existing Flutter, Provider, Isar, and localization patterns before introducing new dependencies.
- Keep changes focused on the requested behavior and run `flutter analyze` and relevant tests after edits.
