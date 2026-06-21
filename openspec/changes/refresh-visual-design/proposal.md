## Why

A fundação de arquitetura (change `add-arch-foundation`) está pronta. Este change entrega a identidade visual "deslumbrante" (dark-neon + glassmorphism + movimento) prometida pelo produto, extraindo uma **biblioteca de componentes reutilizável** (`core/design_system/widgets/`) e tokens de tema (glass, motion), e aplicando-a ao shell e às três telas existentes. É pré-requisito de polimento para as próximas ferramentas (fretboard, pitch pipe, círculo de quintas, acordes), que nascerão já consumindo esses componentes.

## What Changes

- Adiciona tokens de tema: cores de superfície glass (translúcidas), constantes de sigma de blur e durações/curvas de motion (`core/theme/app_glass.dart`, `core/theme/app_motion.dart`, extensões em `app_colors.dart`).
- Cria a biblioteca de componentes `core/design_system/widgets/`: `GlassCard` (frosted glass com `BackdropFilter`), `AppSegmented` (SegmentedButton estilizado), `AppChip` (ChoiceChip estilizado), `SectionTitle`, `ToolHeader`, `AppButton` (botão neon com micro-interação de toque), `GlowingDot` (indicador decorativo) e `AnimatedTabSwitcher` (transição fade+slide ao trocar de aba, preservando estado via IndexedStack).
- Restyle do `AppShell` (bottom nav com superfície glass + transição de aba animada) e das três telas (Metrônomo, Campo Harmônico, Afinador) e da tela de Ajustes usando a biblioteca, sem alterar comportamento funcional.
- Adiciona micro-interações de toque e transições sutis (fade+slide) por toda a navegação.

## Capabilities

### New Capabilities
- `design-system-components`: Biblioteca de componentes visuais reutilizáveis (glassmorfismo + motion) e tokens de tema compartilhados, consumidos por todas as telas.

### Modified Capabilities
- `app-shell`: Adota bottom nav com superfície glass e transição animada entre abas (estado das telas preservado).
- `instrument-tuner`, `harmonic-field-visualizer`, `metronome`: UI restilizada com a biblioteca de componentes (sem mudança de comportamento).

## Impact

- **Código**: Novos `core/design_system/widgets/*`, `core/theme/app_glass.dart`, `core/theme/app_motion.dart`; edições em `app_colors.dart`, `app_theme.dart`, `app_shell.dart` e nas 4 telas. Barrrel export via `core/design_system/widgets.dart`.
- **Dependências**: nenhuma nova (usa `dart:ui` `BackdropFilter`/`ImageFilter`, já disponíveis no Flutter 3.19).
- **Plataformas**: iOS/Android. Risco principal é **performance do `BackdropFilter`** em Android低端 → mitigado com sigma modesto e blur apenas em painéis estáticos (não em listas animadas/CustomPaint).
- **Compatibilidade Flutter 3.19**: usa `MaterialStatePropertyAll` (não `WidgetStatePropertyAll`); `BackdropFilter` via `ClipRRect`.
