## ADDED Requirements

### Requirement: Modo desafio pede acordes aleatórios
O sistema DEVE apresentar acordes para o usuário tocar em uma ordem aleatória por nível.

#### Scenario: Nível iniciante
- **QUANDO** o usuário iniciar o modo desafio no nível 1
- **ENTÃO** o sistema deve pedir apenas acordes abertos (C, G, D, E, A, Am, Em, Dm)

### Requirement: Validar acorde pelo microfone
O sistema DEVE verificar se o som capturado contém as notas esperadas do acorde.

#### Scenario: Acorde correto
- **QUANDO** o usuário tocar o acorde solicitado corretamente
- **ENTÃO** o sistema deve exibir feedback positivo e avançar

### Requirement: Limitar tempo por acorde
O sistema DEVE permitir configurar um tempo limite para cada acorde no desafio.

#### Scenario: Tempo esgotado
- **QUANDO** o usuário não tocar o acorde dentro do tempo limite
- **ENTÃO** o sistema deve marcar como erro e avançar
