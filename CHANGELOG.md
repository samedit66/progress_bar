# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Added

- Added `counter`, `countdown`, and `stack` renderer presets for compact value
  and progress displays.
- Added phase visibility and remaining-value configuration to
  `PB_SPINNER_PROGRESS_RENDERER`.
- Added compact stack phase configuration to
  `PB_STANDARD_PROGRESS_RENDERER`.

## [1.0.0] - 2026-09-27

### Added

- Added spinner presets for ASCII, pie, moon, line, and Braille pixel phases.
- Added `set_show_count` and `set_show_elapsed` to
  `PB_SPINNER_PROGRESS_RENDERER`.

### Changed

- `PB_SPINNER_PROGRESS_RENDERER.make` now uses Unicode moon phases by default.
- Spinner output is compact by default: it shows the description and current
  phase without a counter, elapsed time, or unavailable ETA.

### Compatibility notes

- This release changes the default spinner output and is therefore a breaking
  release for applications that snapshot or parse terminal output.
- Applications that need the previous ASCII phase sequence can use
  `{PB_RENDERER_PRESETS}.spinner`.
- Applications that need the previous counter or elapsed time can enable them
  explicitly with `set_show_count (True)` and `set_show_elapsed (True)`.

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
