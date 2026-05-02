# jmvg-ios-shared

Shared Swift utilities for the JMVG iOS apps (ro-control-ios + ro-tools-ios).

## Layout

```
Sources/JMVGAuth/
  RefreshCoordinator.swift   Single-flight + race-fixed refresh dedupe
Tests/JMVGAuthTests/
  RefreshCoordinatorTests.swift
```

## Wiring it into an app

Both `ro-control-ios` and `ro-tools-ios` consume this package via a
**local-path SPM dependency**. The expected layout on the developer/build Mac:

```
~/projects/JMVG/
  jmvg-ios-shared/      ← this repo
  ro-control-ios/       ← references ../jmvg-ios-shared
  ro-tools-ios/         ← references ../jmvg-ios-shared
```

Each app's `project.yml` declares the dependency:

```yaml
packages:
  JMVGAuth:
    path: ../jmvg-ios-shared

targets:
  <AppName>:
    dependencies:
      - package: JMVGAuth
```

After cloning (or after pulling new shared changes), regenerate the
Xcode project: `xcodegen generate` in each app directory.

## Why local-path instead of a remote URL

iOS apps build on the developer's Mac (xcodebuild + Xcode → TestFlight),
not on Cloud Build. Both apps' source trees live on the same machine
under `~/projects/JMVG/`, so a local-path dependency resolves cleanly
without needing Git submodules or a published release tag.

If the shared package ever ships independently or gets multiple consumers
that don't share a parent directory, switch to a remote URL spec:

```yaml
packages:
  JMVGAuth:
    url: https://github.com/JMVGruzylo/jmvg-ios-shared
    version: 1.0.0
```

## Running the tests

```
swift test
```

(Requires Xcode or Xcode Command Line Tools with XCTest available.)

## Versioning

Lock-step with the apps for now. There's no published version because
both consumers live in the same monorepo-adjacent layout. Tag releases
when the package gains its first independent consumer.
