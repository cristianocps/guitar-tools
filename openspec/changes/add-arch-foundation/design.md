## Context

O app `music_tools` já entrega Afinador (cromático + por corda, afinação padrão), Visualizador de Campo Harmônico e Metrônomo, com `flutter analyze` limpo e 24 testes passando. Os próximos changes (refresh visual, fretboard, pitch pipe, círculo de quintas, biblioteca de acordes, subdivisions) compartilham três necessidades transversais que hoje não existem: (1) afinações além da padrão, (2) uma referência A4 configurável centralizada (hoje 440 Hz hardcoded em `note.dart`) e (3) persistência de preferências. Este change estabelece essas fundações de forma isolada e testável, sem tocar na camada visual (delegada ao próximo change).

Stack: Flutter 3.19.0 / Dart 3.3, Riverpod 2.6, `record` 5.x, `audioplayers` 6.x, `path_provider`. Lints estritos (`prefer_final_locals`, `require_trailing_commas`, `directives_ordering`, `always_declare_return_types`, aspas simples, sem `print`).

## Goals / Non-Goals

**Goals:**
- Generalizar afinação em `Tuning`/`TuningPreset` sem quebrar consumers existentes (compat via re-export).
- Centralizar a referência A4 para que todo cálculo frequência↔nota a honre, mantendo o default 440 Hz (zero regressão).
- Persistir preferências on-device com `shared_preferences`, expostas via Riverpod, com bootstrap antes do primeiro frame.
- Expor uma tela de Ajustes editável.
- Lembrar a última aba/BPM/compasso (quando habilitado) sem introduzir cascade de rebuilds.

**Non-Goals:**
- Editor de afinação customizada (apenas presets).
- Refresh visual / component library de glassmorphism (próximo change `refresh-visual-design`).
- Novas ferramentas (fretboard, pitch pipe, círculo de quintas, acordes, subdivisions) — changes posteriores.
- Tema claro.

## Decisions

### 1. `Tuning` como modelo + presets; `standardTuning` vira alias
**Escolha:** Novo `core/music_theory/tuning.dart` define `GuitarString` (movido de `guitar_tuning.dart`), `Tuning { name, List<GuitarString> strings }` (grave→agudo), `enum TuningPresetId { standard, dropD, dadgad, openG, halfStepDown }` e `TuningPreset` com `static const standard/dropD/...` e `static List<TuningPreset> all`. `guitar_tuning.dart` torna-se `export 'tuning.dart';` (compat). `standardTuning` (List<GuitarString>) é mantido como `const ... = TuningPreset.standard.tuning.strings` e marcado `@Deprecated`.
**Razão:** fonte única de verdade; presets são dados const testáveis; re-export evita migrar todos os imports de uma vez. Sem dependência circular (tuning.dart só importa note.dart).
**Presets (grave→agudo):**
- Standard: E2 A2 D3 G3 B3 E4
- Drop D: D2 A2 D3 G3 B3 E4
- DADGAD: D2 A2 D3 G3 A3 D4
- Open G: D2 G2 D3 G3 B3 D4
- Half-Step Down: Eb2 Ab2 Db3 Gb3 Bb3 Eb4

### 2. A4 parametrizável sem quebrar a API existente
**Escolha:** `Note.frequencyOf(double a4)` (método); `Note.frequency` (getter) mantido como `=> frequencyOf(440)` (compat, default). `noteFromFrequency(double freq, {double a4Reference = 440})`. `GuitarString.frequencyOf(double a4)` + `frequency` getter (default 440).
**Fórmulas:** `freq = a4 * 2^((midi-69)/12)`; `midiFloat = 69 + 12*log2(freq/a4)`.
**Razão:** aditivo e retrocompatível — todos os call-sites e testes existentes (A4==440) continuam corretos; novos consumidores passam a referência configurada.

### 3. Settings store: `Notifier<AppSettings>` sobre `SharedPreferences`
**Escolha:**
- `sharedPreferencesProvider = Provider<SharedPreferences>` (lança `UnimplementedError` se não overridden — força injeção explícita).
- `settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>` lê/escreve o `SharedPreferences` injetado. Cada setter atualiza o `state` (cópia imutável) e persiste a chave correspondente.
- `AppSettings` imutável com `copyWith`, `==`, `hashCode`. Campos: `a4Reference` (double, 415–466), `notation` (Notation), `defaultTuningPreset` (TuningPresetId), `rememberLast` (bool), `lastTabIndex` (int), `lastBpm` (int), `lastBeatsPerBar` (int).
- Providers derivados de conveniência: `a4ReferenceProvider`, `notationProvider`, `selectedTuningProvider` (default = afinação-padrão da configuração), `defaultTuningPresetProvider`.
**Razão:** Riverpod é o padrão do projeto; injeção explícita torna o store testável sem channel nativo (override com `SharedPreferences.setMockInitialValues`).

### 4. Bootstrap antes do primeiro frame
**Escolha:** `main()` assíncrono: `WidgetsFlutterBinding.ensureInitialized()`; `await SharedPreferences.getInstance()`; `runApp(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)], child: app))`. Default values valem até a resolução; como a injeção é síncrona pós-await, todo `ref.read` após `runApp` já vê preferências carregadas.
**Razão:** satisfaz "boot antes do primeiro paint" e "ref reads seguros pré-load".

### 5. `activeTabProvider` vira Notifier (restore + persist)
**Escolha:** `NotifierProvider<ActiveTabNotifier, AppTab>`; `build()` lê (uma vez, via `ref.read`) `settingsProvider` e restaura `lastTabIndex` (clampado) quando `rememberLast`, senão `AppTab.metronome`. Método `selectIndex(int)` atualiza o estado e persiste `lastTabIndex`.
**Razão:** `ref.read` em `build()` evita cascade (editar A4 não reseta a aba). Providers são criados preguiçosamente após `runApp`, quando settings já estão prontos.

### 6. Persistir BPM/compasso sem cascade
**Escolha:** `MetronomeSettingsNotifier.build()` lê (uma vez, `ref.read`) `settingsProvider` para iniciar `bpm`/`beatsPerBar` quando `rememberLast`; `setBpm`/`setBeatsPerBar` persistem via `ref.read(settingsProvider.notifier)`. **Não** há `ref.watch` de settings → editar A4 não reinicia/para o metrônomo.
**Razão:** isola estado transitório (`isPlaying`) do estado persistido.

### 7. Tela de Ajustes
**Escolha:** `features/settings/settings_screen.dart` (rota push), campos: A4 (−/＋ e valor em Hz, 415–466), notação (segmented letras/solfège), afinação padrão (lista de presets), "lembrar última aba/BPM/compasso" (switch). Usa tokens de tema existentes; empacotada em `AppBackground`.
**Razão:** ponto único de edição; entrada por gear no app bar do `AppShell` (transparente, `extendBodyBehindAppBar: true`).

## Risks & Mitigations
- **Cascade de rebuilds:** uso de `ref.read` (não `watch`) em `build()` de notifiers de estado transitório.
- **Tests sem platform channel:** `widget_test` e testes de settings fazem override de `sharedPreferencesProvider` com instância mockada (`SharedPreferences.setMockInitialValues`).
- **A4 default 440:** métodos mantêm default 440; testes existentes seguem verdes.
- **`standardTuning` deprecated:** após migrar o Afinador para `selectedTuningProvider`, nenhum código de produção referencia o const; `@Deprecated` é seguro.

## Testing Strategy
- Unit: presets de afinação (alturas das cordas por preset); `Note.frequencyOf`/`noteFromFrequency` com A4≠440 (ex.: 442 Hz → A4 ligeiramente agudo); round-trip de `AppSettings` (gravar/ler).
- Widget: app boot mantém funcionando (override do provider); gear abre a tela de Ajustes.
- Mantém: todos os testes existentes verdes.
