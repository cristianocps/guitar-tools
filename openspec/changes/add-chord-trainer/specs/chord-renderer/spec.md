## ADDED Requirements

### Requirement: Desenhar diagrama de acorde
O sistema DEVE renderizar um diagrama de acorde com 6 cordas verticais e até 4-5 casas horizontais.

#### Scenario: Posição aberta de C
- **QUANDO** o usuário visualizar C major na primeira posição
- **ENTÃO** o sistema deve desenhar os trastes, cordas, dedilhamento e bolinhas nos fretes corretos

### Requirement: Indicar cordas abertas e mudas
O sistema DEVE mostrar "O" para cordas abertas e "X" para cordas mudas no diagrama.

#### Scenario: C major
- **QUANDO** a 6ª corda for muda no acorde C
- **ENTÃO** o sistema deve exibir "X" na 6ª corda

### Requirement: Desenhar pestanas
O sistema DEVE desenhar uma barra horizontal indicando pestana quando a posição tiver `barres`.

#### Scenario: F major com pestana
- **QUANDO** o acorde F major exigir pestana na primeira casa
- **ENTÃO** o sistema deve desenhar a barra de pestana sobre as cordas 1 a 6

### Requirement: Destacar dedo por nota
O sistema DEVE exibir o número do dedo dentro de cada bolinha do acorde.

#### Scenario: D major
- **QUANDO** o sistema renderizar D major
- **ENTÃO** cada nota pressionada deve mostrar o dedo sugerido (1, 2, 3, 4)
