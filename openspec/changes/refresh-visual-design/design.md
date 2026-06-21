## Context

Após `add-arch-foundation`, o app tem 3 telas funcionais (Metrônomo, Campo Harmônico, Afinador) + Ajustes, com `flutter analyze` limpo e 42 testes passando. O visual atual usa gradient `AppBackground`, helpers `NeonGlow`/`PulseScale`, e widgets Material padrão (`SegmentedButton`, `ChoiceChip`, `IconButton.filled`, `SwitchListTile`) sem um vocabulário de componentes próprio. Este change introduz glassmorfismo + motion coesos via uma biblioteca de componentes, sem mudar funcionalidade.

Stack: Flutter 3.19.0 / Dart 3.3. Lints estritos. `MaterialStatePropertyAll` (não `WidgetStatePropertyAll`).

## Goals / Non-Goals

**Goals:**
- Tokens centralizados de glass (cores translúcidas, sigma de blur) e de motion (durações/curvas).
- Biblioteca de componentes reutilizável e testável (`GlassCard`, `AppSegmented`, `AppChip`, `SectionTitle`, `ToolHeader`, `AppButton`, `GlowingDot`, `AnimatedTabSwitcher`).
- Aplicar consistentemente no shell + 4 telas.
- Transição de aba animada (fade+slide) preservando estado.
- Manter `flutter analyze` limpo e todos os testes verdes + adicionar testes de componentes.

**Non-Goals:**
- Novas ferramentas (fretboard/pitch pipe/círculo/acordes) — changes posteriores.
- Expansão para 5 abas (ocorre quando fretboard/acordes forem adicionados).
- Tema claro; profiling fino de FPS (apenas sigma modesto + blur em painéis estáticos).

## Decisions

### 1. Tokens de glass + motion
**Escolha:** `core/theme/app_glass.dart` (`AppGlass { blurSigma=14, blurSigmaStrong=24, radius=20 }`) e `core/theme/app_motion.dart` (`AppMotion { instant=100ms, fast=180ms, medium=300ms, slow=480ms; emphasis=easeOutCubic, standard=easeInOut, enter=easeOut }`). Extensões em `app_colors.dart`: `glassSurface` (branco ~10%), `glassSurfaceStrong`, `glassBorder` (branco ~14%).
**Razão:** centraliza; sigma modesto (14) mantém FPS em Android低端.

### 2. `GlassCard`: frosted glass em painéis estáticos
**Escolha:** `ClipRRect` + `BackdropFilter(blur(sigma))` + `Container(color: glassSurface, border: glassBorder)`. Padding configurável. Usado em cabeçalhos, painéis de detalhe e seções — **não** dentro de listas rolantes CustomPaint (perf).
**Razão:** o `BackdropFilter` desfoca o `AppBackground` atrás do card, dando o efeito frosted sobre o gradiente.

### 3. Componentes estilizados wrappers de Material
**Escolha:**
- `AppSegmented<T>`: `SegmentedButton` com `ButtonStyle` (background translúcido, selected = `AppColors.primary` com leve elevação, foreground branco).
- `AppChip`: `ChoiceChip` com `selectedColor: primary`, label style do tema, padding consistente.
- `SectionTitle`: rótulo pequeno em `AppColors.primary` (uppercase-ish via letterSpacing do `AppTypography.label`).
- `ToolHeader`: título de tela (`AppTypography.headline`) opcionalmente com subtítulo, centralizado.
- `AppButton`: botão filled com `NeonGlow` + micro-interação de escala no toque (`AnimatedScale` em tap down/up).
- `GlowingDot`: ponto com glow radial (decorativo, para estados/indicadores).
**Razão:** reaproveita Material 3 (acessibilidade/semântica) com identidade própria; barra de export `widgets.dart`.

### 4. `AnimatedTabSwitcher`: fade+slide preservando estado
**Escolha:** `StatefulWidget` + `SingleTickerProviderStateMixin`. Mantém `IndexedStack` (estado das 3 telas preservado); no `didUpdateWidget`, se `index` mudou, `_controller.forward(from: 0)`. Envolve o `IndexedStack` em `SlideTransition` + `FadeTransition` (offset pequeno, ex. `(0, 0.04)`, duração `AppMotion.medium`, curva `enter`).
**Razão:** o `IndexedStack` troca instantaneamente para a nova child (visível) e a animação de entrada aplica-se à child ativa — sem perder estado, sem cross-fade dispendioso de todas as children.

### 5. Shell: bottom nav glass + transição
**Escolha:** `NavigationBar` com `backgroundColor` translúcido (glassSurface) + `surfaceTintColor: transparent`; corpo envolvido por `AnimatedTabSwitcher`. Entrada de Ajustes (gear) já existe.
**Razão:** M3 `NavigationBar` aceita cor translúcida; o blur do glass vem do `AppBackground` já presente atrás.

## Risks & Mitigations
- **`BackdropFilter` perf (Android低端):** sigma modesto (14); apenas em painéis estáticos; nunca em `CustomPaint` animado (pendulum/strings/circle continuam sem blur).
- **Estado das telas ao animar:** `IndexedStack` preserva; a transição só afeta a child ativa.
- **Regressão visual/funcional:** manter `flutter analyze` + todos os testes existentes; os textos semânticos verificados no `widget_test` ('Metrônomo','Afinador','Campo','Ajustes') continuam presentes.

## Testing Strategy
- Widget: `GlassCard` renderiza `BackdropFilter`; `AppSegmented` dispara `onChanged`; `AppChip` reflete seleção; `AnimatedTabSwitcher` mantém IndexedStack e responde à mudança de index.
- Mantém: todos os 42 testes existentes verdes.
