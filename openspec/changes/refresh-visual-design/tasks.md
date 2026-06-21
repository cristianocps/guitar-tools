## 1. Tokens de tema

- [x] 1.1 Adicionar cores de glass a `app_colors.dart` (`glassSurface`, `glassSurfaceStrong`, `glassBorder`)
- [x] 1.2 Criar `core/theme/app_glass.dart` (`AppGlass { blurSigma=14, blurSigmaStrong=24, radius=20 }`)
- [x] 1.3 Criar `core/theme/app_motion.dart` (`AppMotion { instant/fast/medium/slow; emphasis/standard/enter }`)

## 2. Biblioteca de componentes

- [x] 2.1 `core/design_system/widgets/glass_card.dart` (`GlassCard`: ClipRRect + BackdropFilter + surface translúcida)
- [x] 2.2 `core/design_system/widgets/app_segmented.dart` (`AppSegmented<T>` estilizado)
- [x] 2.3 `core/design_system/widgets/app_chip.dart` (`AppChip` estilizado)
- [x] 2.4 `core/design_system/widgets/section_title.dart` + `tool_header.dart`
- [x] 2.5 `core/design_system/widgets/app_button.dart` (`AppButton` neon + micro-interação)
- [x] 2.6 `core/design_system/widgets/glowing_dot.dart`
- [x] 2.7 `core/design_system/widgets/animated_tab_switcher.dart` (IndexedStack + fade/slide)
- [x] 2.8 Barrel `core/design_system/widgets.dart`

## 3. Aplicação

- [x] 3.1 `AppShell`: bottom nav glass + `AnimatedTabSwitcher`
- [x] 3.2 Metrônomo: `ToolHeader`, `GlassCard`, `AppButton` (play)
- [x] 3.3 Campo Harmônico: `ToolHeader`, `GlassCard` (detalhe), `AppSegmented`, `AppChip`
- [x] 3.4 Afinador: `AppSegmented`, `AppChip`, `GlassCard`
- [x] 3.5 Ajustes: `GlassCard` por seção + `SectionTitle` compartilhado (remover `_SectionTitle` privado)

## 4. Testes

- [x] 4.1 `test/design_system/components_test.dart`: GlassCard (BackdropFilter), AppSegmented (onChanged), AppChip (seleção), AnimatedTabSwitcher (IndexedStack + mudança de index)
- [x] 4.2 Garantir testes existentes (42) verdes

## 5. Validação

- [x] 5.1 `flutter analyze` limpo
- [x] 5.2 `flutter test` passando
- [x] 5.3 `openspec validate refresh-visual-design`
