## ADDED Requirements

### Requirement: Tocar intervalo de referência
O sistema DEVE tocar duas notas sequenciais (ascendente) formando um intervalo musical.

#### Scenario: Intervalo maior de segunda
- **QUANDO** o exercício selecionar o intervalo de segunda maior a partir de Dó4
- **ENTÃO** o sistema deve tocar Dó4 seguido de Ré4

### Requirement: Validar resposta por pitch class
O sistema DEVE comparar a nota tocada pelo usuário com a nota esperada ignorando oitava.

#### Scenario: Usuário acerta a nota esperada
- **QUANDO** a nota esperada for Sol e o usuário tocar Sol3
- **ENTÃO** o sistema deve considerar a resposta correta

#### Scenario: Usuário erra por semitom
- **QUANDO** a nota esperada for Sol e o usuário tovir Fá# ou Sol#
- **ENTÃO** o sistema deve considerar a resposta incorreta e registrar o semitom de erro

### Requirement: Cobrir intervalos diatônicos ascendentes
O sistema DEVE oferecer exercícios de intervalos de segunda a oitava, maiores, menores, justos e aumentados/diminutos quando aplicável.

#### Scenario: Lista de intervalos disponíveis
- **QUANDO** o usuário acessar o ear training
- **ENTÃO** o sistema deve apresentar níveis cobrindo 2ª, 3ª, 4ª, 5ª, 6ª, 7ª e 8ª

### Requirement: Feedback imediato
O sistema DEVE exibir feedback visual imediato após cada tentativa (acerto, erro e nota tocada).

#### Scenario: Resposta correta
- **QUANDO** o usuário tocar a nota esperada
- **ENTÃO** o sistema deve exibir indicador de acerto e avançar para a próxima rodada

#### Scenario: Resposta incorreta
- **QUANDO** o usuário tocar uma nota diferente da esperada
- **ENTÃO** o sistema deve exibir indicador de erro, tocar novamente o intervalo e permitir nova tentativa
