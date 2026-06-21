## ADDED Requirements

### Requirement: Referência de afinação A4 configurável
O sistema SHALL permitir que o usuário configure a referência de afinação A4 (faixa 415–466 Hz, default 440 Hz) e SHALL usar essa referência em toda conversão frequência↔nota (Afinador e Campo Harmônico), de forma centralizada.

#### Scenario: Padrão 440 mantém comportamento atual
- **WHEN** a referência A4 é o padrão (440 Hz)
- **THEN** a frequência de A4 mapeia exatamente a 440 Hz e os cents relativos são calculados como hoje

#### Scenario: Referência diferente altera a grade de afinação
- **WHEN** o usuário define A4 = 442 Hz
- **THEN** a nota A4 passa a corresponder a 442 Hz e uma frequência de 442 Hz é classificada como afinada (0 cents), enquanto 440 Hz passa a ser classificada como ligeiramente grave

### Requirement: Notação de notas configurável
O sistema SHALL permitir alternar entre notação por letras (C/D/E/...) e solfejo (Dó/Ré/Mi/...) e SHALL aplicar essa notação onde os nomes de notas são exibidos ao usuário.

#### Scenario: Alternar para solfejo
- **WHEN** o usuário seleciona a notação solfejo
- **THEN** as notas passam a ser exibidas como Dó, Ré, Mi, ... nas telas que mostram nomes de notas

### Requirement: Afinações selecionáveis (presets)
O sistema SHALL oferecer afinações predefinidas (Padrão, Drop D, DADGAD, Open G, Half-Step Down) e SHALL permitir selecionar uma afinação padrão nas configurações, reutilizada pelo modo por corda do Afinador.

#### Scenario: Padrão é a afinação Standard
- **WHEN** nenhuma preferência foi definida
- **THEN** a afinação padrão é a Standard (E2 A2 D3 G3 B3 E4)

#### Scenario: Selecionar Drop D
- **WHEN** o usuário escolhe a afinação Drop D
- **THEN** o modo por corda do Afinador passa a avaliar as cordas como D2 A2 D3 G3 B3 E4

### Requirement: Persistência de preferências
O sistema SHALL persistir on-device (via `shared_preferences`) as preferências do usuário (referência A4, notação, afinação padrão, lembrar-último) e SHALL restaurá-las ao iniciar o app, carregando-as antes do primeiro frame.

#### Scenario: Preferência sobrevive a reinicialização
- **WHEN** o usuário define A4 = 442 Hz e reinicia o app
- **THEN** a referência A4 carregada é 442 Hz

#### Scenario: Defaults quando nada foi persistido
- **WHEN** o app é iniciado pela primeira vez
- **THEN** os valores carregados são os defaults (440 Hz, letras, Standard, lembrar-último ligado)

### Requirement: Lembrar último estado
O sistema SHALL oferecer uma opção "lembrar último estado" (default ligado) que, quando ativa, restaura a última aba ativa e os últimos BPM/compasso do metrônomo ao reabrir o app.

#### Scenario: Restaurar última aba
- **WHEN** "lembrar último" está ligado e o usuário reabre o app
- **THEN** a aba ativa é a última utilizada na sessão anterior

#### Scenario: Desligar não restaura
- **WHEN** "lembrar último" está desligado
- **THEN** o app abre na aba padrão (Metrônomo) com BPM/compasso padrão

### Requirement: Tela de Ajustes
O sistema SHALL fornecer uma tela de Ajustes acessível por uma entrada no app bar, permitindo editar a referência A4, a notação, a afinação padrão e a opção "lembrar último".

#### Scenario: Editar A4
- **WHEN** o usuário abre os Ajustes e altera A4 para 442 Hz
- **THEN** a nova referência é aplicada imediatamente às telas de áudio e persistida

## MODIFIED Requirements

### Requirement: Disponibilidade condicional ao microfone
O sistema SHALL ativar a captura de áudio do afinador somente quando a permissão de microfone estiver concedida; caso contrário, SHALL exibir um estado informativo. (Inalterado em comportamento; a conversão interna passa a honrar a referência A4 configurável.)

#### Scenario: Sem permissão de microfone
- **WHEN** o afinador é aberto sem permissão de microfone
- **THEN** o sistema exibe uma mensagem e uma ação para conceder a permissão, sem realizar detecção

### Requirement: Modo de afinação por corda
O sistema SHALL oferecer um modo guiado por corda para violão/guitarra de 6 cordas, usando a afinação selecionável (preset) como alvo, permitindo ao usuário selecionar a corda alvo e indicando se ela está grave, aguda ou afinada, honrando a referência A4 configurada.

#### Scenario: Selecionar corda alvo
- **WHEN** o usuário seleciona a corda "A" (Lá) na afinação Standard
- **THEN** o sistema passa a avaliar o som capturado em relação a A2 e exibe o status de afinação daquela corda

#### Scenario: Afinação não padrão altera os alvos
- **WHEN** a afinação Drop D está selecionada e o usuário seleciona a 6ª corda
- **THEN** o alvo passa a ser D2 em vez de E2
