# Changelog

All notable changes to this project are documented in this file.

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

