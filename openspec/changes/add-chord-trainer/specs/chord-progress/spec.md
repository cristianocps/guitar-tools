## ADDED Requirements

### Requirement: Definir níveis de acordes
O sistema DEVE organizar acordes em níveis por dificuldade crescente.

#### Scenario: Nível 1
- **QUANDO** o usuário acessar o nível 1
- **ENTÃO** deve ver apenas acordes abertos maiores e menores

### Requirement: Persistir progresso de acordes
O sistema DEVE salvar estrelas e status de desbloqueio por acorde/nível.

#### Scenario: Acorde aprendido
- **QUANDO** o usuário completar o modo aprender de um acorde
- **ENTÃO** o sistema deve marcar o acorde como aprendido e salvar estrelas

### Requirement: Desbloquear próximo nível
O sistema DEVE desbloquear o próximo nível quando o usuário obter pelo menos 1 estrela no nível atual.

#### Scenario: Passar de nível
- **QUANDO** o usuário obtiver 60% de acerto no nível atual
- **ENTÃO** o próximo nível deve ser desbloqueado
