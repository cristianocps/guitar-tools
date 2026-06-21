## ADDED Requirements

### Requirement: GlassCard renders a frosted-glass panel
The design system SHALL provide a `GlassCard` widget that renders a rounded panel with a blurred backdrop, translucent surface, and subtle border.

#### Scenario: Static panel usage
- **WHEN** a screen uses `GlassCard` as a static header or detail panel
- **THEN** the widget renders a `ClipRRect`, a `BackdropFilter` with configurable blur sigma, and a translucent surface color

### Requirement: AppSegmented provides styled single selection
The design system SHALL provide an `AppSegmented<T>` widget backed by Material `SegmentedButton` with app-specific colors and shape.

#### Scenario: Mode selection
- **WHEN** the user taps an unselected segment
- **THEN** the widget invokes `onChanged` with the selected value and visually highlights the active segment

### Requirement: AppChip provides styled selectable chips
The design system SHALL provide an `AppChip` widget backed by Material `ChoiceChip` with app-specific selected/unselected colors.

#### Scenario: Option selection
- **WHEN** the user taps an unselected chip
- **THEN** the widget invokes `onSelected(true)` and displays the selected visual state

### Requirement: ToolHeader and SectionTitle provide consistent headings
The design system SHALL provide `ToolHeader` for screen titles and `SectionTitle` for section labels using the app's typography and accent color.

#### Scenario: Screen title
- **WHEN** a tool screen is rendered
- **THEN** the screen title is displayed via `ToolHeader` using the headline style and optional subtitle

### Requirement: AppButton provides a neon action button
The design system SHALL provide an `AppButton` with a neon glow background, icon, label, and a scale-down micro-interaction on press.

#### Scenario: Primary action
- **WHEN** the user presses the button
- **THEN** the button scales down and triggers `onPressed`

### Requirement: AnimatedTabSwitcher preserves state with animated transitions
The design system SHALL provide an `AnimatedTabSwitcher` that wraps an `IndexedStack` and applies a fade+slide entrance animation when the active index changes.

#### Scenario: Tab change
- **WHEN** the selected tab index changes
- **THEN** the new child becomes visible with a fade/slide entrance while previous children retain their state
