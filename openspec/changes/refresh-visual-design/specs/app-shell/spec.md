## MODIFIED Requirements

### Requirement: Bottom navigation uses a glass surface
The `AppShell` bottom navigation SHALL render with a translucent glass surface and backdrop blur instead of the default opaque surface.

#### Scenario: Shell rendered
- **WHEN** the app shell is displayed
- **THEN** the `NavigationBar` uses `AppColors.glassSurface` as its background color and is wrapped in a `BackdropFilter`

### Requirement: Tab content transitions with state preservation
The `AppShell` SHALL wrap its body in `AnimatedTabSwitcher` so changing tabs plays a fade+slide entrance animation while preserving each tab's state.

#### Scenario: Switching tabs
- **WHEN** the user selects a different bottom navigation destination
- **THEN** the new tab content animates in with a fade+slide transition and the previously visible tab keeps its state
