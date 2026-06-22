## Why

O app já ajuda o usuário a afinar, visualizar campo harmônico, treinar ritmo e escalas, mas não ensina acordes de forma interativa. Adicionar um módulo de aprendizado de acordes com uma experiência de jogo aumenta o engajamento e completa o ciclo de estudo do guitarrista, aproveitando o detector de pitch para validar execução em tempo real.

## What Changes

- Nova aba/módulo **Acordes** dentro da seção Treino.
- Integração com o banco de dados `chords-db` (tomossals/chords-db) como fonte de formas de acordes para violão.
- Visualização interativa do diagrama de acorde com cordas, casas, dedos e pestanas.
- Modos de jogo:
  - **Aprender**: mostra o acorde, toca as notas e o usuário repete para validar.
  - **Desafio**: app pede um acorde e valida pelo microfone se o usuário tocou corretamente.
  - **Sequência (progressão)**: sequência de acordes no tempo, estilo "Simon says".
- Sistema de níveis por dificuldade (acordes abertos, barra, 7ª, nona, etc.).
- Persistência de progresso com estrelas e desbloqueio de níveis.

## Capabilities

### New Capabilities

- `chord-data-source`: importar e modelar dados do `chords-db` no domínio do app.
- `chord-renderer`: desenhar diagramas de acordes com pestanas, dedos e cordas abertas/mudas.
- `chord-learning-mode`: modo guiado de aprendizado com som de referência e validação por microfone.
- `chord-challenge-mode`: modo desafio onde o app pede acordes e valida a execução.
- `chord-sequence-mode`: sequência de acordes no tempo com metrônomo.
- `chord-progress`: persistência de níveis, estrelas e desbloqueio de acordes.

### Modified Capabilities

- Nenhum capability existente é alterado em comportamento.

## Impact

- Novo asset JSON com dados do `chords-db` em `assets/chords/`.
- Novos diretórios em `lib/features/training/chords/`.
- Extensões em `lib/core/music_theory/` para representar acordes e pestanas.
- Reaproveita `PitchChallengeValidator`, `ToneGenerator`, `MetronomeEngine` e `TrainingProgressRepository`.
- Nova entrada no `TrainingHomeScreen` para o módulo Acordes.
