## ADDED Requirements

### Requirement: Localizar nota no braço
O sistema DEVE desafiar o usuário a tocar uma nota específica em uma corda e casa específicas da guitarra.

#### Scenario: Nota na terceira corda
- **QUANDO** o desafio for "toque Ré na 3ª corda, 7ª casa"
- **ENTÃO** o sistema deve validar se o usuário tocou a pitch class Ré

### Requirement: Validar nota ignorando oitava
O sistema DEVE aceitar qualquer oitava da pitch class correta como resposta válida.

#### Scenario: Oitava flexível
- **QUANDO** o desafio espera Ré e o usuário tocar Ré3 ou Ré5
- **ENTÃO** o sistema deve considerar a resposta correta

### Requirement: Modo Scale Runner
O sistema DEVE guiar o usuário a tocar as notas de uma escala em sequência no tempo do metrônomo.

#### Scenario: Escala maior de Dó
- **QUANDO** o exercício selecionar escala maior de Dó
- **ENTÃO** o sistema deve apresentar as notas Dó, Ré, Mi, Fá, Sol, Lá, Si, Dó e aguardar que o usuário as toque na ordem

### Requirement: Escalas suportadas
O sistema DEVE suportar pelo menos as escalas maior, menor natural, pentatônica maior e pentatônica menor.

#### Scenario: Seleção de escala
- **QUANDO** o usuário escolher uma escala pentatônica menor
- **ENTÃO** o sistema deve gerar desafios com os intervalos [0, 3, 5, 7, 10]

### Requirement: Afinação de guitarra padrão
O sistema DEVE usar a afinação padrão E2 A2 D3 G3 B3 E4 para mapear cordas e casas.

#### Scenario: Mapeamento de casa
- **QUANDO** a afinação for padrão e o desafio pedir a 5ª corda na 3ª casa
- **ENTÃO** a nota esperada deve ser Dó3
