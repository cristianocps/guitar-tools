## 1. Modelo de afinação

- [x] 1.1 Criar `core/music_theory/tuning.dart` com `GuitarString` (movido), `Tuning { name, List<GuitarString> strings }`, `enum TuningPresetId`, `TuningPreset` (standard, dropD, dadgad, openG, halfStepDown) + `static all`
- [x] 1.2 Reduzir `guitar_tuning.dart` a `export 'tuning.dart';` (compat); manter `standardTuning` como alias const marcado `@Deprecated`

## 2. Referência A4 configurável

- [x] 2.1 Adicionar `Note.frequencyOf(double a4)`; manter `frequency` getter (default 440); adicionar `GuitarString.frequencyOf(double a4)`
- [x] 2.2 Adicionar parâmetro `{double a4Reference = 440}` a `noteFromFrequency`

## 3. Store de configurações

- [x] 3.1 Adicionar dependência `shared_preferences` (compatível Flutter 3.19)
- [x] 3.2 Criar `core/settings/settings.dart` com `AppSettings` imutável (campos + copyWith/==/hashCode) e defaults
- [x] 3.3 Criar `core/settings/settings_providers.dart`: `sharedPreferencesProvider`, `SettingsNotifier` (ler/escrever prefs), providers derivados (`a4ReferenceProvider`, `notationProvider`, `selectedTuningProvider`, `defaultTuningPresetProvider`)

## 4. Bootstrap e shell

- [x] 4.1 `main.dart` assíncrono: carregar `SharedPreferences` e injetar via `ProviderScope.overrides` antes do `runApp`
- [x] 4.2 Converter `activeTabProvider` em Notifier (restore via `ref.read` quando `rememberLast`; `selectIndex` persiste)
- [x] 4.3 Adicionar entrada de Ajustes (gear) no app bar do `AppShell` (`extendBodyBehindAppBar`); abrir `SettingsScreen` via `Navigator.push`

## 5. Tela de Ajustes

- [x] 5.1 Criar `features/settings/settings_screen.dart`: A4 (−/＋, 415–466), notação (segmented), afinação padrão (presets), "lembrar último" (switch), empacotada em `AppBackground`

## 6. Fio da configuração nas features

- [x] 6.1 Afinador: modo por corda usa `selectedTuningProvider`; honrar `a4ReferenceProvider` em `noteFromFrequency` e na frequência-alvo da corda; honrar `notationProvider` nos nomes de notas
- [x] 6.2 Campo Harmônico: honrar `a4ReferenceProvider` em `noteFromFrequency` e `notationProvider` nos nomes de notas/acordes
- [x] 6.3 Metrônomo: `MetronomeSettingsNotifier.build()` restaura BPM/compasso (quando `rememberLast`); setters persistem (sem `watch`/cascade)

## 7. Testes

- [x] 7.1 `test/music_theory/tuning_test.dart`: alturas das cordas de cada preset (grave→agudo); `byId`; 6 cordas numeradas; `frequencyOf`
- [x] 7.2 `test/music_theory/note_test.dart` (estendido): A4≠440 em `frequencyOf` e `noteFromFrequency`
- [x] 7.3 `test/settings/settings_test.dart`: round-trip de persistência (gravar/ler) com mock de `SharedPreferences`; defaults; clamp; fallback de lixo
- [x] 7.4 Ajustar `test/widget_test.dart`: override de `sharedPreferencesProvider` + teste da entrada de Ajustes

## 8. Validação

- [x] 8.1 `flutter analyze` limpo
- [x] 8.2 `flutter test` passando (existentes + novos: 42 testes)
- [x] 8.3 Validar specs com `openspec validate add-arch-foundation`
