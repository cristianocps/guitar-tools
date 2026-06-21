## Why

O app atual possui três ferramentas funcionais (Afinador, Campo Harmônico, Metrônomo) mas carece de fundações que qualquer evolução futura exige: a afinação é um único `standardTuning` hardcoded, a referência de A4 (440 Hz) está fixa em duas fórmulas dentro de `note.dart`, a notação (letras/solfège) não é editável pelo usuário, e não há persistência de preferências. Antes de adicionar novas ferramentas (fretboard, pitch pipe, círculo de quintas, biblioteca de acordes) e do refresh visual, este change estabelece a **base de arquitetura**: um modelo `Tuning` generalizável com presets, uma referência A4 configurável centralizada, um store de configurações persistido (`shared_preferences`) com tela de Ajustes, e o bootstrap dessas configurações antes do primeiro frame. É o pré-requisito direto dos changes subsequentes (`refresh-visual-design`, fretboard/pitch pipe, subdivisions/chords).

## What Changes

- Generaliza a afinação em um modelo `Tuning` (nome + `List<GuitarString>` grave→agudo) com `TuningPreset` (Standard, Drop D, DADGAD, Open G, Half-Step Down). O `standardTuning` legado passa a ser `TuningPreset.standard.tuning.strings` (const re-exportado para compatibilidade).
- Torna a **referência A4 configurável**: `Note.frequencyOf(a4)` e `noteFromFrequency(freq, {a4Reference})` aceitam a referência; o padrão permanece 440 Hz (nenhum teste ou call-site existente quebra).
- Cria `core/settings/` com um store Riverpod persistido por `shared_preferences`: `a4Reference`, `notation`, `defaultTuningPreset`, `rememberLast`, `lastTabIndex`, `lastBpm`, `lastBeatsPerBar`. Defaults: 440, letras, standard, true.
- Faz o **bootstrap** das configurações antes do `runApp` (main assíncrono carrega o `SharedPreferences` e injeta via override); valores-default valem até a resolução.
- Adiciona uma **tela de Ajustes** (entrada por ícone de engrenagem no app bar): editar A4 (±/spinner), alternar notação letras/solfège, escolher afinação padrão, alternar "lembrar última aba/BPM/compasso".
- Fia a configuração pelo app: Afinador (modo por corda) passa a usar o `selectedTuningProvider`; Afinador e Campo Harmônico honram a referência A4 configurada; a aba ativa e o BPM/compasso do metrônomo são lembrados quando `rememberLast` está ligado.

## Capabilities

### New Capabilities
- `app-settings`: Store de configurações do usuário persistido on-device (`shared_preferences`) com referência A4, notação, afinação padrão e preferência de "lembrar último estado"; tela de Ajustes para editá-las.

### Modified Capabilities
- `app-shell`: Adiciona entrada para a tela de Ajustes no app bar e passa a restaurar a última aba ativa a partir das configurações (quando "lembrar último" está ligado).
- `instrument-tuner`: Passa a usar afinações selecionáveis (presets) no modo por corda e a honrar a referência A4 configurada nas conversões frequência↔nota.

## Impact

- **Código**: Novos `core/music_theory/tuning.dart`, `core/settings/*`, `features/settings/settings_screen.dart`; refactor leve em `note.dart` (A4 parametrizável), `app_providers.dart` (`activeTabProvider` vira Notifier), `main.dart` (bootstrap), `app_shell.dart` (gear + restore), `tuner_screen.dart` e `harmonic_field_screen.dart` (fio do A4 e afinação), `core/metronome_engine/providers.dart` (persistir BPM/compasso).
- **Dependências**: adiciona `shared_preferences` (compatível com Flutter 3.19 / Dart 3.3).
- **Plataformas**: iOS e Android — `shared_preferences` exige Podfile/Gradle já presentes; sem novas permissões nativas.
- **Risco técnico**: ordem de inicialização (settings prontos antes do primeiro paint), cascade de rebuilds entre providers (mitigada lendo settings uma única vez em `build()` e evitando `watch` onde o estado transitório seria resetado) e regression nos testes existentes (mantidos verdes; `widget_test` ganha override do provider).
