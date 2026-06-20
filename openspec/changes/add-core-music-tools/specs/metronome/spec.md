## ADDED Requirements

### Requirement: Controle de tempo (BPM)
O sistema SHALL permitir ao usuário definir o tempo entre 20 e 280 BPM, e SHALL refletir a mudança imediatamente durante a reprodução.

#### Scenario: Ajustar BPM
- **WHEN** o usuário ajusta o BPM para 120
- **THEN** o metrônomo passa a soar a 120 batidas por minuto

### Requirement: Assinatura de compasso e acentos
O sistema SHALL permitir configurar a assinatura de compasso (mínimo 2/4, 3/4, 4/4 e 6/8) e SHALL acentuar o primeiro tempo de cada compasso de forma distinguível dos demais.

#### Scenario: Acento no primeiro tempo
- **WHEN** o metrônomo está em 4/4 e em reprodução
- **THEN** o primeiro tempo de cada compasso soa diferente (acentuado) em relação aos tempos 2, 3 e 4

### Requirement: Iniciar e parar com temporização precisa
O sistema SHALL iniciar e parar a reprodução sob controle do usuário e SHALL manter o tempo estável, com drift acumulado inferior a 0,5% em sessões de até 5 minutos.

#### Scenario: Temporização estável
- **WHEN** o metrônomo roda a um BPM fixo por 5 minutos
- **THEN** o número efetivo de batidas corresponde ao BPM configurado com erro menor que 0,5%

#### Scenario: Parar e retomar
- **WHEN** o usuário para e inicia novamente o metrônomo
- **THEN** a contagem reinicia a partir do tempo 1 do primeiro compasso

### Requirement: Animação de pêndulo sincronizada
O sistema SHALL exibir uma animação de pêndulo que oscila de forma sincronizada com os tempos, servindo como feedback visual do andamento.

#### Scenario: Pêndulo no tempo
- **WHEN** o metrônomo está em reprodução
- **THEN** o pêndulo atinge os extremos de seu movimento alinhado com as batidas, na velocidade correspondente ao BPM atual

### Requirement: Feedback sonoro do clique
O sistema SHALL produzir um clique audível a cada tempo (com timbre distinto para o tempo acentuado), reproduzido com baixa latência.

#### Scenario: Clique audível
- **WHEN** o metrônomo está em reprodução com som ativado
- **THEN** um clique é reproduzido a cada tempo e o clique do primeiro tempo é distinguível dos demais
