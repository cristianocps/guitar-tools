## Why

O `music_tools` já entrega utilitários sólidos (afinador, campo harmônico e metrônomo), mas não ajuda o usuário a *treinar* habilidades musicais de forma guiada. Adicionar exercícios interativos com validação por microfone aumenta o valor percebido do app, reaproveita os motores de áudio e teoria musical existentes e abre caminho para um modelo freemium futuro.

## What Changes

- Nova aba principal **Treino** na navegação inferior, agrupando três módulos:
  - **Ear Training**: toca intervalos e valida a resposta do usuário via detector de pitch.
  - **Fretboard Trainer**: desafia o usuário a localizar notas e tocar escalas no braço da guitarra.
  - **Exercícios com backing**: exercícios rítmicos e de digitação acompanhados pelo metrônomo.
- Novo motor de síntese de tons em memória para notas de referência dos exercícios.
- Novo `RhythmDetector` para detectar onsets no stream de PCM e validar exercícios rítmicos.
- Persistência de progresso com Hive: definições de exercícios, tentativas e progresso do usuário.
- Gamificação baseada em estrelas (1–3) e desbloqueio de níveis por porcentagem de acerto.

## Capabilities

### New Capabilities

- `ear-training`: tocar intervalos musicais e validar a reprodução do usuário pelo microfone.
- `fretboard-trainer`: desafiar localização de notas e execução de escalas no braço da guitarra com validação por pitch.
- `rhythm-exercises`: exercícios rítmicos com metrônomo e detecção de onsets pelo microfone.
- `technique-exercises`: exercícios de digitação (escalas/arpégios) com metrônomo e validação por pitch.
- `training-progress`: persistência, recompensas e desbloqueio de níveis de exercícios.

### Modified Capabilities

- Nenhum capability existente é alterado em comportamento.

## Impact

- Novas dependências: `hive`, `hive_flutter` (persistência).
- Novos diretórios em `lib/features/training/` com submódulos.
- Extensões em `lib/core/audio/` (`ToneGenerator`, `RhythmDetector`).
- Extensões em `lib/core/music_theory/` para suportar novos tipos de escalas e intervalos.
- Ajuste na navegação principal (`lib/app/`) para incluir a aba Treino.
