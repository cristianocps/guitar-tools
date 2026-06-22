## Context

O app `music_tools` possui hoje:
- `lib/core/audio/`: captura de PCM (`record`) e detector YIN de pitch.
- `lib/core/metronome_engine/`: scheduler de tempo e sintetizador de click.
- `lib/core/music_theory/`: notas, escalas, acordes, afinação.
- `lib/features/`: tuner, harmonic_field, metronome e settings.

Os novos recursos de treino reaproveitam esses blocos. A principal adição é a validação por microfone em tempo real, que exige integrar áudio, teoria musical e metrônomo de forma coesa.

## Goals / Non-Goals

**Goals:**
- Adicionar aba "Treino" com Ear Training, Fretboard Trainer, Rhythm Exercises e Technique Exercises.
- Reaproveitar `AudioCaptureService`, `YinPitchDetector`, `MetronomeEngine` e `ClickSynth`.
- Persistir progresso com Hive de forma desacoplada da UI.
- Entregar exercícios validados por microfone com feedback visual e estrelas.

**Non-Goals:**
- Não implementar pagamento ou modelos freemium agora.
- Não adicionar afinações alternativas no Fretboard Trainer.
- Não suportar intervalos descendentes/harmônicos no Ear Training.
- Não usar samples de áudio externos.

## Decisions

### 1. Hive para persistência
**Escolha:** Adicionar `hive` e `hive_flutter`.
**Por quê:** Progresso de exercícios precisa de estrutura (exercícios, tentativas, progresso do usuário). `shared_preferences` funcionaria, mas Hive é mais adequado para dados tipados e consultas futuras sem depender de JSON manual.
**Alternativa considerada:** `shared_preferences` + JSON, descartada pela tendência de crescimento dos dados de treino.

### 2. Instrumento real + microfone
**Escolha:** O usuário toca o instrumento real e o app valida via áudio.
**Por quê:** É o diferencial do app frente a treinadores touch-only. Reaproveita o detector de pitch existente.
**Alternativa considerada:** Input por tela, descartado por menor valor percebido.

### 3. Shell independente por módulo
**Escolha:** Cada módulo de treino terá sua própria tela completa.
**Por quê:** Embora um shell comum fosse mais enxuto, as telas independentes permitem evoluir cada módulo sem acoplamento. A navegação interna é simples (lista de níveis → exercício).
**Alternativa considerada:** Shell comum compartilhado, descartado por preferência do usuário.

### 4. Sintetizador em memória
**Escolha:** Criar `ToneGenerator` baseado em senoide/damping, similar ao `ClickSynth`.
**Por quê:** Gera notas de referência sem adicionar assets, mantendo o app offline e leve.
**Alternativa considerada:** Samples de áudio, descartados por tamanho e manutenção.

### 5. `RhythmDetector` separado
**Escolha:** Novo detector de onsets no core de áudio, escutando o mesmo stream PCM.
**Por quê:** Não altera o `YinPitchDetector` e permite reutilizar o `AudioCaptureService` para pitch e ritmo.
**Alternativa considerada:** Integrar detecção de onset no pitch detector, descartada por misturar responsabilidades.

### 6. Validação por pitch class
**Escolha:** Ear Training e Fretboard validam pitch class, ignorando oitava.
**Por quê:** Reduz falso-negativo quando o usuário toca a nota certa em oitava diferente da esperada.
**Alternativa considerada:** Validar oitava exata, descartada por ser muito rígida para iniciantes.

### 7. BottomNavigationBar com 4 abas
**Escolha:** Adicionar Treino como quarta aba principal.
**Por quê:** Visibilidade imediata e integração natural com os utilitários existentes.
**Alternativa considerada:** Menu lateral, descartado por adicionar clique extra.

## Risks / Trade-offs

- **Latência do áudio**: validação por microfone pode sofrer com latência de buffer. → Mitigação: usar `AudioEncoder.pcm16bits` e janelas pequenas; testar em dispositivos reais.
- **Falsos positivos no onset**: ruído ambiente pode gerar onsets espúrios. → Mitigação: noise gate ajustável e threshold por nível.
- **Complexidade da UI**: três módulos podem gerar telas grandes. → Mitigação: dividir em widgets pequenos e Riverpod providers específicos.
- **Tamanho do Hive**: schemas podem mudar. → Mitigação: versionar boxes e usar `TypeAdapter` com campos opcionais.

## Migration Plan

- Adicionar dependências do Hive no `pubspec.yaml`.
- Inicializar Hive no `main.dart` antes de `runApp`.
- Criar modelos Hive com `TypeAdapter`.
- Implementar core (tone generator, rhythm detector, teoria musical estendida).
- Implementar features de treino.
- Atualizar navegação principal.
- Rodar `flutter pub get`, `flutter analyze` e `flutter test`.

## Open Questions

- Qual será o limite máximo de BPM nos exercícios de técnica? (sugestão: 200 BPM)
- O detector de onset precisará de calibração automática de threshold por ambiente?
