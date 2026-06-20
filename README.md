# Music Tools

App mobile (Flutter) com utilitários para músicos, principalmente guitarristas:

- **Afinador** — cromático e por corda, com detecção de pitch em tempo real.
- **Visualizador de campo harmônico** — círculo interativo gerado a partir da nota tocada/selecionada.
- **Metrônomo** — BPM e compasso configuráveis, com animação de pêndulo.

## Decisões técnicas (compatibilidade de pacotes)

Toolchain: Flutter **3.19.0** (Dart 3.3.0), gerenciado via `mise`.

Pacotes escolhidos e **validados** com `flutter pub get` contra Flutter 3.19:

| Pacote | Versão | Uso |
| --- | --- | --- |
| `flutter_riverpod` | ^2.6.1 | State management |
| `record` | ^5.2.0 | Captura de microfone (PCM 16-bit via `AudioRecorder.startStream`, Android + iOS) |
| `audioplayers` | ^6.4.0 | Cliques do metrônomo (modo `lowLatency`) |
| `flutter_lints` | ^4.0.0 | Lint/estilo (dev) |

> Não foi necessário elevar o Flutter: todos os pacotes acima resolvem em 3.19.0.
> Versões mais novas (ex.: `record` 7.x) exigem Dart > 3.3 e não foram adotadas por ora.

## Comandos

```bash
flutter pub get      # instalar dependências
flutter analyze      # análise estática (deve passar limpa)
flutter test         # testes
flutter run          # rodar no dispositivo/emulador conectado
```

O toolchain (Flutter, Node para o CLI `openspec`) é ativado via `mise` em WSL (Ubuntu).
Veja `AGENTS.md` para detalhes de ambiente e convenções.

> **iOS:** o `permission_handler` exige habilitar a permissão de microfone no
> `ios/Podfile` (gerado no primeiro build). No bloco `post_install`, adicione:
> `installer.pods_project.targets.each { |t| t.build_configurations.each { |c|
> c.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'PERMISSION_MICROPHONE=1'] } }`.
> O `NSMicrophoneUsageDescription` já está em `ios/Runner/Info.plist`.
>
> **Android:** os plugins de áudio exigem toolchain mais nova que o default do
> Flutter 3.19. Já configurado: `minSdkVersion 23`, `compileSdk 35`, AGP
> `8.5.2`, Gradle `8.7`, Kotlin `1.9.24` (`android/app/build.gradle`,
> `android/settings.gradle`, `android/gradle/wrapper/`). Requer `build-tools;35.0.0`
> e `platforms;android-35` (instalados via `sdkmanager`).

## Validação

- `flutter analyze` ✓ sem issues
- `flutter test` ✓ 24 testes (teoria musical, YIN/pitch, motor do metrônomo, smoke do app)
- **Pendente (manual):** testes em dispositivo iOS e Android reais — latência de
  áudio, precisão do metrônomo e fluidez das animações.

## Arquitetura

- `lib/core/` — theme, design system, teoria musical, áudio (captura + YIN), motor do metrônomo.
- `lib/features/` — `tuner`, `harmonic_field`, `metronome`.

Mudanças são gerenciadas de forma spec-driven em `openspec/changes/`.
