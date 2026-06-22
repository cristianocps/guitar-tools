## ADDED Requirements

### Requirement: Definir exercícios com metadados
O sistema DEVE armazenar definições de exercícios contendo identificador, tipo, nível, título, descrição e parâmetros.

#### Scenario: Exercício de ear training
- **QUANDO** o sistema carregar os exercícios
- **ENTÃO** deve existir uma definição para o nível 1 de ear training com tipo e parâmetros adequados

### Requirement: Persistir tentativas
O sistema DEVE salvar cada tentativa de exercício com pontuação, estrelas, precisão, duração e timestamp.

#### Scenario: Tentativa concluída
- **QUANDO** o usuário finalizar um exercício
- **ENTÃO** o sistema deve persistir a tentativa no Hive

### Requirement: Calcular estrelas por porcentagem de acerto
O sistema DEVE converter a porcentagem de acerto em 1 a 3 estrelas.

#### Scenario: Uma estrela
- **QUANDO** a porcentagem de acerto for maior ou igual a 60% e menor que 75%
- **ENTÃO** o sistema deve atribuir 1 estrela

#### Scenario: Duas estrelas
- **QUANDO** a porcentagem de acerto for maior ou igual a 75% e menor que 90%
- **ENTÃO** o sistema deve atribuir 2 estrelas

#### Scenario: Três estrelas
- **QUANDO** a porcentagem de acerto for maior ou igual a 90%
- **ENTÃO** o sistema deve atribuir 3 estrelas

### Requirement: Desbloquear próximo nível
O sistema DEVE desbloquear o nível seguinte quando o usuário obtiver pelo menos 1 estrela no nível atual.

#### Scenario: Passar de nível
- **QUANDO** o usuário completar um exercício com 70% de acerto
- **ENTÃO** o sistema deve desbloquear o próximo nível

### Requirement: Exibir progresso na lista de exercícios
O sistema DEVE mostrar, para cada exercício, se está bloqueado e a melhor pontuação obtida.

#### Scenario: Lista de níveis
- **QUANDO** o usuário abrir a tela de módulo
- **ENTÃO** o sistema deve exibir os níveis bloqueados/desbloqueados e as estrelas conquistadas
