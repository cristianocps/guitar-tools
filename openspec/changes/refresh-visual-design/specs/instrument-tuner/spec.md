## MODIFIED Requirements

### Requirement: Tuner screen uses design-system components
The Tuner screen SHALL use `AppSegmented` for mode selection, `AppChip` for string selection, and `GlassCard` for the note display.

#### Scenario: Tuner screen rendered
- **WHEN** the Tuner tab is visible
- **THEN** the chromatic/string mode selector is an `AppSegmented`, the string picker uses `AppChip`, and the detected note is shown inside a `GlassCard`
