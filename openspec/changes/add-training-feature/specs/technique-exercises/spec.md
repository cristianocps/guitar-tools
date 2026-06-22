## ADDED Requirements

### Requirement: Exercícios de digitação com metrônomo
O sistema DEVE apresentar uma sequência de notas (escala ou arpejo) para o usuário tocar acompanhado pelo metrônomo.

#### Scenario: Escala maior em colcheias
- **QUANDO** o exercício selecionar escala maior de Lá em andamento de 80 BPM
- **ENTÃO** o metrônomo deve tocar em 80 BPM e o sistema deve aguardar cada nota da escala no tempo

### Requirement: Validar notas tocadas
O sistema DEVE comparar cada nota tocada pelo usuário com a próxima nota esperada da sequência.

#### Scenario: Nota correta na sequência
- **QUANDO** a próxima nota esperada for Mi e o usuário tocar Mi
- **ENTÃO** o sistema deve avançar para a próxima nota

#### Scenario: Nota incorreta na sequência
- **QUANDO** a próxima nota esperada for Mi e o usuário tocar Ré
- **ENTÃO** o sistema deve registrar erro, manter a mesma nota esperada e exibir feedback

### Requirement: Aumento gradual de BPM
O sistema DEVE permitir exercícios com metas de velocidade crescente entre níveis.

#### Scenario: Progressão de velocidade
- **QUANDO** o usuário passar de nível
- **ENTÃO** o BPM de referência deve aumentar em passos de 10 BPM até um limite máximo configurado

### Requirement: Registrar precisão e velocidade
O sistema DEVE calcular a pontuação combinando acerto das notas e proximidade com o tempo do metrônomo.

#### Scenario: Performance limpa
- **QUANDO** o usuário tocar todas as notas corretas e alinhadas ao metrônomo
- **ENTÃO** o sistema deve atribuir 3 estrelas
