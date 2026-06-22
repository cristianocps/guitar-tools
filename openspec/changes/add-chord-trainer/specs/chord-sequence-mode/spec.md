## ADDED Requirements

### Requirement: Sequência de acordes no tempo
O sistema DEVE apresentar uma sequência de acordes para o usuário tocar acompanhado pelo metrônomo.

#### Scenario: Progressão I-V-vi-IV
- **QUANDO** o usuário iniciar o modo sequência com C-G-Am-F
- **ENTÃO** o metrônomo deve tocar e o app deve trocar de acorde a cada compasso

### Requirement: Validar mudança de acorde
O sistema DEVE detectar quando o usuário troca para o próximo acorde correto no tempo.

#### Scenario: Troca no compasso
- **QUANDO** o próximo acorde for G e o usuário tocar G no pulso do metrônomo
- **ENTÃO** o sistema deve considerar a troca correta

### Requirement: Aumentar dificuldade com BPM
O sistema DEVE aumentar o BPM progressivamente entre níveis do modo sequência.

#### Scenario: Passar de nível
- **QUANDO** o usuário completar uma sequência com sucesso
- **ENTÃO** o próximo nível deve ter BPM maior
