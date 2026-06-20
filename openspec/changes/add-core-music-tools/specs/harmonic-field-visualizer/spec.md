## ADDED Requirements

### Requirement: Entrada da nota tônica
O sistema SHALL aceitar a nota tônica do campo harmônico de duas formas: (a) a partir da nota detectada pelo microfone em tempo real, ou (b) por seleção manual do usuário.

#### Scenario: Nota detectada pelo microfone
- **WHEN** o afinador/microfone detecta uma nota com confiança suficiente
- **THEN** o sistema define essa nota como tônica do campo harmônico exibido

#### Scenario: Seleção manual
- **WHEN** o usuário seleciona manualmente uma nota (ex.: "Dó")
- **THEN** o sistema define essa nota como tônica, independentemente do microfone

### Requirement: Geração do campo harmônico
O sistema SHALL gerar o campo harmônico correspondente à tônica, exibindo os sete graus naturais (I–VII) e seus respectivos acordes (tríades), tanto para o modo maior quanto para o modo menor.

#### Scenario: Campo maior
- **WHEN** a tônica é "Dó" e o modo selecionado é "maior"
- **THEN** o sistema exibe os graus I–VII com os acordes Dó, Rém, Mib, Fá, Sol, Lám, Sib° (equivalentes em notação)

#### Scenario: Alternar para menor
- **WHEN** o usuário alterna o modo para "menor" mantendo a tônica
- **THEN** o sistema recalcula e exibe o campo harmônico menor correspondente

### Requirement: Visualização circular interativa
O sistema SHALL apresentar o campo harmônico como uma visualização circular interativa, posicionando os graus/acordes ao redor de um círculo e destacando a tônica.

#### Scenario: Tônica destacada
- **WHEN** o campo harmônico é exibido
- **THEN** a tônica (grau I) aparece destacada em relação aos demais graus no círculo

#### Scenario: Selecionar um grau
- **WHEN** o usuário toca em um grau/acorde do círculo
- **THEN** o sistema exibe detalhes daquele acorde (nome e composição de notas)

### Requirement: Atualização em tempo real
O sistema SHALL atualizar o campo harmônico exibido em tempo real conforme a nota tônica muda (por detecção ou seleção).

#### Scenario: Mudança de tônica ao tocar
- **WHEN** o usuário toca uma nota diferente e ela é detectada
- **THEN** o círculo é reorganizado para refletir o novo campo harmônico sem reiniciar a tela
