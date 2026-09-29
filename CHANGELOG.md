# Changelog

All notable changes to this project are documented in this file.

## [1.0.0] - 2026-09-29

### Added

- Replaced `PB_PROGRESS_GROUP` and progress renderer classes with `PB_DISPLAY`
  and the single configurable `PB_FORMATTER` API.
- Renamed renderer presets to `PB_FORMATTER_PRESETS` and preserved the existing
  standard, spinner, counter, countdown, stack, and character presets.
- Added the protected `PB_DISPLAY.emit` extension point for redirected output.
- Added spinner presets for ASCII, pie, moon, line, and Braille pixel phases.
- Added `set_show_count` and `set_show_timing` to `PB_FORMATTER`.
- Added `counter`, `countdown`, and `stack` renderer presets for compact value
  and progress displays.
- Added phase visibility and remaining-value configuration to
  `PB_SPINNER_PROGRESS_RENDERER`.
- Added compact stack phase configuration to
  `PB_STANDARD_PROGRESS_RENDERER`.

### Changed

- Updated the demo, documentation, formatting recipe, tests, and README for
  the new API and formatter set.
- Updated the demo recording with the message output example.
- `PB_FORMATTER.make` now uses ASCII phases and elapsed timing by default for
  unknown totals.
- Compact counter, countdown, and spinner presets disable timing by default.
- Progress display output now clears terminal rows before redrawing bars or
  messages, preserving clean output when line lengths change.

### Compatibility notes

- This release changes the default spinner output and is therefore a breaking
  release for applications that snapshot or parse terminal output.
- Applications that need a different phase sequence can use
  `{PB_FORMATTER_PRESETS}.spinner` or another formatter preset.
- Applications that need to hide elapsed time can use
  `set_show_timing (False)`.

## [0.2.0] - 2026-09-24

### Added

- Added `PB_TIMING_RENDERER`, which decorates any progress renderer with
  elapsed time and estimated time remaining (ETA).
- Added platform-specific clock implementations for Gobo Eiffel and
  EiffelStudio.
- Added timing renderer documentation and test coverage.
- Added a `just gif` recipe for regenerating the terminal demo.

### Changed

- Progress bars now use the Unicode renderer with timing information by
  default.
- Reworked `PB_UNICODE_PROGRESS_RENDERER` on top of the shared block progress
  renderer.
- Expanded the demo application with spinner, message, nested-bar, and timing
  examples.
- Refreshed the demo GIF.

### Compatibility notes

- The default output now includes Unicode rendering, elapsed time, and ETA.
- ETA is displayed as `--:--:--` for unknown totals and before measurable
  progress.
- Applications that need the previous basic renderer can select it explicitly:

  ```eiffel
  bar.set_renderer (create {PB_BASIC_PROGRESS_RENDERER})
  ```
