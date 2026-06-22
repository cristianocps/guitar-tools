## ADDED Requirements

### Requirement: Modo aprender com som de referência
O sistema DEVE tocar as notas do acorde em sequência e em conjunto para o usuário ouvir.

#### Scenario: Tocar C major
- **QUANDO** o usuário abrir o modo aprender de C major
- **ENTÃO** o app deve tocar as notas do acorde e aguardar o usuário repetir

### Requirement: Validar execução do acorde
O sistema DEVE detectar pelo microfone se o usuário tocou o acorde correto.

#### Scenario: Usuário acerta C
- **QUANDO** o usuário tocar as notas C, E, G do acorde C major
- **ENTÃO** o sistema deve considerar o acorde correto

### Requirement: Permitir alternar posições
O sistema DEVE permitir ao usuário alternar entre as diferentes posições do mesmo acorde.

#### Scenario: Variações de C
- **QUANDO** o usuário selecionar outra posição de C major
- **ENTÃO** o diagrama e o som devem refletir a nova posição
