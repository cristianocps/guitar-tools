## ADDED Requirements

### Requirement: Modo cromático de afinação
O sistema SHALL, no modo cromático, capturar o áudio do microfone e exibir em tempo real a nota musical detectada (com oitava) e o desvio em centésimos (cents) em relação à nota mais próxima, usando A4 = 440 Hz como referência.

#### Scenario: Nota afinada
- **WHEN** o usuário toca uma nota dentro de ±5 cents da nota alvo
- **THEN** o sistema exibe a nota com oitava e um indicador de "afinado"

#### Scenario: Nota desafinada
- **WHEN** o usuário toca uma nota com desvio superior a ±10 cents
- **THEN** o sistema exibe a nota, o valor aproximado do desvio em cents e um indicador de "grave" ou "agudo"

### Requirement: Modo de afinação por corda
O sistema SHALL oferecer um modo guiado por corda para violão/guitarra de 6 cordas em afinação padrão (E2, A2, D3, G3, B3, E4), permitindo ao usuário selecionar a corda alvo e indicando se ela está grave, aguda ou afinada.

#### Scenario: Selecionar corda alvo
- **WHEN** o usuário seleciona a corda "A" (Lá)
- **THEN** o sistema passa a avaliar o som capturado em relação a A2 e exibe o status de afinação daquela corda

#### Scenario: Corda afinada
- **WHEN** a frequência detectada está dentro de ±5 cents da corda alvo selecionada
- **THEN** o sistema indica visualmente que a corda está afinada

### Requirement: Indicador visual de afinação
O sistema SHALL exibir um indicador visual claro (ex.: agulha, barra ou cor) que mostre a direção e a magnitude do desvio em tempo real.

#### Scenario: Desvio grave
- **WHEN** a nota tocada está abaixo da alvo
- **THEN** o indicador aponta para o lado "grave"

#### Scenario: Desvio agudo
- **WHEN** a nota tocada está acima da alvo
- **THEN** o indicador aponta para o lado "agudo"

### Requirement: Visualização interativa das cordas
O sistema SHALL renderizar uma visualização interativa das cordas que destaca a corda/nota ativa e reage à detecção de pitch (ex.: vibração ou realce da corda correspondente).

#### Scenario: Corda ativa destacada
- **WHEN** uma nota é detectada com confiança suficiente
- **THEN** a corda correspondente à nota é destacada/anima na visualização

### Requirement: Estabilidade da leitura
O sistema SHALL aplicar suavização temporal à detecção de pitch para que a nota exibida não oscile de forma instável durante uma nota sustentada.

#### Scenario: Nota sustentada
- **WHEN** o usuário sustenta uma nota estável
- **THEN** a nota exibida permanece fixa, sem oscilar entre notas vizinhas

### Requirement: Disponibilidade condicional ao microfone
O sistema SHALL ativar a captura de áudio do afinador somente quando a permissão de microfone estiver concedida; caso contrário, SHALL exibir um estado informativo.

#### Scenario: Sem permissão de microfone
- **WHEN** o afinador é aberto sem permissão de microfone
- **THEN** o sistema exibe uma mensagem e uma ação para conceder a permissão, sem realizar detecção
