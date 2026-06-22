## ADDED Requirements

### Requirement: Detectar onsets no áudio
O sistema DEVE detectar transientes de energia no stream de PCM e emitir eventos de "batida detectada".

#### Scenario: Palma no tempo
- **QUANDO** o usuário bater palmas próximo ao microfone
- **ENTÃO** o RhythmDetector deve emitir um evento de onset com timestamp

### Requirement: Comparar onset com grade do metrônomo
O sistema DEVE medir o desvio de cada onset detectado em relação ao tempo esperado do metrônomo.

#### Scenario: Batida no tempo
- **QUANDO** o usuário tocar exatamente no pulso do metrônomo
- **ENTÃO** o desvio deve ser menor que 50 ms

#### Scenario: Batida atrasada
- **QUANDO** o usuário tocar 120 ms após o pulso esperado
- **ENTÃO** o sistema deve registrar como atraso significativo

### Requirement: Padrões rítmicos por nível
O sistema DEVE oferecer padrões rítmicos progressivos: semínimas, colcheias, síncopas e tercinas.

#### Scenario: Nível iniciante
- **QUANDO** o usuário selecionar o primeiro nível
- **ENTÃO** o exercício deve usar apenas semínimas e colcheias com subdivisão simples

### Requirement: Feedback de precisão rítmica
O sistema DEVE exibir, ao final do exercício, a porcentagem de batidas dentro da janela de tolerância.

#### Scenario: Resultado do exercício
- **QUANDO** o usuário completar 16 batidas
- **ENTÃO** o sistema deve calcular quantas batidas estiveram dentro da tolerância e atribuir estrelas
