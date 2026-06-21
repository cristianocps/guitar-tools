## MODIFIED Requirements

### Requirement: Harmonic Field screen uses design-system components
The Harmonic Field screen SHALL use `ToolHeader`, `AppSegmented` for scale mode selection, `GlassCard` for degree details, and `AppChip` for tonic selection.

#### Scenario: Harmonic Field screen rendered
- **WHEN** the Harmonic Field tab is visible
- **THEN** the title is rendered via `ToolHeader`, the scale mode selector is an `AppSegmented`, the selected degree details appear in a `GlassCard`, and the tonic selector uses `AppChip`
