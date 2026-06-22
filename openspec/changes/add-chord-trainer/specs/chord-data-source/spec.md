## ADDED Requirements

### Requirement: Importar dados do chords-db
O sistema DEVE carregar os dados de acordes do `chords-db` a partir de um asset JSON no app.

#### Scenario: Dados de guitarra disponíveis
- **QUANDO** o app inicializar
- **ENTÃO** os dados de acordes de violão devem estar acessíveis em memória

### Requirement: Modelar acorde no domínio
O sistema DEVE representar um acorde com key, suffix, posições (frets, fingers, barres, baseFret) e notas MIDI.

#### Scenario: Acorde C major
- **QUANDO** o sistema carregar o acorde C major
- **ENTÃO** deve conter pelo menos uma posição com frets, dedos e notas MIDI correspondentes

### Requirement: Suportar afinação padrão
O sistema DEVE mapear as notas do acorde para a afinação padrão EADGBE.

#### Scenario: Notas do acorde C
- **QUANDO** o usuário selecionar a primeira posição de C major
- **ENTÃO** o sistema deve identificar as notas tocadas como C, E, G, C, E
