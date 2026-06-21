## MODIFIED Requirements

### Requirement: Metronome screen uses design-system components
The Metronome screen SHALL use `ToolHeader`, `GlassCard` for the control panel, and `AppButton` for the play/stop action.

#### Scenario: Metronome screen rendered
- **WHEN** the Metronome tab is visible
- **THEN** the title is rendered via `ToolHeader`, the BPM/time-signature controls sit inside a `GlassCard`, and the play/stop action is an `AppButton`

### Requirement: Time signature selector uses AppChip
The Metronome time signature selector SHALL use `AppChip` widgets instead of plain Material chips.

#### Scenario: Changing time signature
- **WHEN** the user taps a time signature chip
- **THEN** the selected chip shows the active visual state and the metronome updates its beats per bar
