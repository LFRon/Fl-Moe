# Debian packaging scaffold

This directory is a basic `flutter_to_debian 2.0.2` configuration. No Debian
package was built when this scaffold was added.

## Current layout

- `debian.yaml` describes the x86-64 Flutter bundle and the basic Debian
  control metadata, including its top-level runtime dependencies.
- `gui/fl_moe.desktop` is the source desktop-entry template.
- `gui/fl_moe.png` reuses the current Fl-Moe mascot as a provisional launcher
  icon.
- `../tool/build_debian.dart` validates `control.Depends` and injects it into
  the package metadata before delegating to `flutter_to_debian`.

With the current values, the packaged Flutter bundle is intended for
`/opt/fl-moe`, and the executable resolved by `flutter_to_debian` is
`/opt/fl-moe/fl_moe`. The tool adds `Icon`, `Exec`, and `TryExec` to the copy of
the desktop entry placed under `/usr/share/applications`.

## Fields to review before packaging

- Keep `control.Version` synchronized with the version in `pubspec.yaml`.
- Replace the provisional `Maintainer` value with the final Debian maintainer
  identity.
- Review the package name, architecture, installation parent, description,
  desktop categories, translations, keywords, and launcher icon.
- Review the dependency package names and minimum versions against the final
  target distribution, then add Debian policy files, maintainer scripts and
  copyright metadata.

`flutter_to_debian 2.0.2` only reads `Version`, `Package`, `Architecture`,
`Maintainer`, and `Description` from the `control` map. Its generated control
file uses the built-in `optional` priority and does not consume custom
`Section` or `Depends` values from `debian.yaml`. Use the project wrapper so the
configured dependencies are not silently omitted:

```shell
# Parse and display Depends without creating a package.
dart run tool/build_debian.dart --check

# Package an existing Linux release bundle when the rules are finalized.
dart run tool/build_debian.dart --build
```

Calling `dart run flutter_to_debian build` directly bypasses this compatibility
layer and therefore still emits an empty `Depends` field. The wrapper does not
run `flutter build linux`; `--build` expects the release bundle to exist first.
