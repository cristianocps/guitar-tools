## Context

O app já possui:
- `lib/core/music_theory/`: notas, escalas, acordes triades, afinação, braço.
- `lib/core/audio/`: captura de PCM, detector YIN, validador de pitch, gerador de tons.
- `lib/core/metronome_engine/`: metrônomo e scheduler.
- `lib/features/training/`: módulos de ear training, fretboard, ritmo e digitação.
- Persistência com Hive via `TrainingProgressRepository`.

A base para o módulo de acordes já existe. A principal adição é um banco de dados externo de formas de acordes e a renderização visual de diagramas.

## Goals / Non-Goals

**Goals:**
- Adicionar módulo de acordes dentro da aba Treino.
- Integrar dados do `chords-db` para guitarra (afinação padrão).
- Renderizar diagramas de acordes interativos.
- Entregar modos Aprender, Desafio e Sequência.
- Validar execução pelo microfone reaproveitando `PitchChallengeValidator`.
- Persistir progresso com estrelas e desbloqueio de níveis.

**Non-Goals:**
- Não suportar outros instrumentos além de guitarra nesta versão.
- Não editar/criar acordes personalizados.
- Não usar samples de áudio reais; os tons serão sintetizados.

## Decisions

### 1. Fonte de dados: chords-db via asset JSON
**Escolha:** Incluir o `guitar.json` do `chords-db` como asset estático.
**Por quê:** O formato é simples, aberto (MIT) e contém milhares de variações. Não requer chamadas de rede.
**Alternativa considerada:** Modelar manualmente um subconjunto de acordes. Descartada por limitar o conteúdo.

### 2. Modelo de domínio separado do JSON
**Escolha:** Criar classes `Chord`, `ChordPosition`, `ChordFinger` mapeando o JSON.
**Por quê:** Desacopla a UI do formato do `chords-db` e permite validações/transformações.

### 3. Renderização customizada com CustomPainter
**Escolha:** Implementar `ChordDiagramPainter` para desenhar o diagrama.
**Por quê:** Dá controle total sobre pestanas, dedos, cordas abertas/mudas e destaques. Mais flexível que usar imagens pré-renderizadas.

### 4. Validação por pitch class
**Escolha:** Validar se o som capturado contém as pitch classes do acorde, ignorando oitavas e duplicatas.
**Por quê:** Um acorde pode ser tocado em diferentes ordens e oitavas; validar pitch class é suficiente e robusto.

### 5. Modo sequência reaproveita metrônomo
**Escolha:** Usar `MetronomeEngine` e `ClickPlayer` existentes para o modo sequência.
**Por quê:** Mantém consistência com outros exercícios e evita duplicação.

### 6. Persistência reaproveita TrainingProgressRepository
**Escolha:** Usar o mesmo repositório Hive dos exercícios de treino.
**Por quê:** O domínio de progresso é idêntico (exercício, estrelas, desbloqueio).

## Risks / Trade-offs

- **Tamanho do asset JSON**: `guitar.json` pode ter centenas de KB. → Mitigação: carregar sob demanda e manter apenas guitarra nesta versão.
- **Ambiguidade de validação**: alguns acordes compartilham notas (ex: C6 e Am7). → Mitigação: validar contra as notas exatas do acorde solicitado; no modo aprender, aceitar qualquer posição válida.
- **Latência na validação**: strumming pode gerar múltiplos onsets; o validador deve considerar uma janela de tempo. → Mitigação: coletar pitch classes detectadas em uma janela de ~1s antes de avaliar.
- **UX de pestanas**: iniciantes podem ter dificuldade. → Mitigação: indicar claramente pestanas e dedos, e introduzir acordes com pestana apenas em níveis mais avançados.

## Migration Plan

- Adicionar `assets/chords/guitar.json` e registrar em `pubspec.yaml`.
- Criar modelos e parser em `lib/core/music_theory/chords_db.dart`.
- Criar `ChordDiagramPainter` e widget de diagrama.
- Implementar controllers dos três modos.
- Integrar na navegação de Treino.
- Testar `flutter analyze` e `flutter test`.

## Open Questions

- Devemos incluir apenas um subconjunto de acordes no asset para reduzir tamanho?
- Qual será a janela de tempo ideal para validação de acordes strumming vs. arpeggio?
- O modo sequência deve usar progressões fixas ou geradas aleatoriamente?
