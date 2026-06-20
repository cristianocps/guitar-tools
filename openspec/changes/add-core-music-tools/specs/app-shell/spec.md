## ADDED Requirements

### Requirement: App inicializável e multiplataforma
O sistema SHALL ser um aplicativo Flutter que inicia sem erros e exibe uma tela inicial em iOS e Android.

#### Scenario: Inicialização bem-sucedida
- **WHEN** o usuário abre o aplicativo em um dispositivo iOS ou Android
- **THEN** o app inicializa e apresenta a tela inicial dentro de 3 segundos, sem travamentos

### Requirement: Navegação entre utilitários
O sistema SHALL fornecer uma navegação inferior (bottom navigation) que permite alternar entre os três utilitários: Afinador, Campo Harmônico e Metrônomo.

#### Scenario: Alternar de utilitário
- **WHEN** o usuário seleciona um item da navegação inferior
- **THEN** a tela do utilitário correspondente é exibida imediatamente preservando o estado de cada utilitário ao retornar

#### Scenario: Tela padrão na inicialização
- **WHEN** o aplicativo é aberto
- **THEN** o utilitário Metrônomo (ou o primeiro da lista) é exibido como tela inicial padrão

### Requirement: Design system e tema visual consistentes
O sistema SHALL aplicar um design system unificado (paleta de cores, tipografia, espaçamentos e widgets base) em todas as telas, garantindo uma identidade visual coerente e animações fluidas a 60 fps.

#### Scenario: Tema aplicado em todas as telas
- **WHEN** o usuário navega por qualquer utilitário
- **THEN** todas as telas compartilham a mesma paleta, tipografia e estilo de componentes

### Requirement: Gerenciamento de permissão de microfone
O sistema SHALL solicitar a permissão de microfone com uma justificativa clara antes de usar o áudio, e SHALL tratar de forma graciosa a negação, mantendo os utilitários que não dependem de microfone totalmente funcionais.

#### Scenario: Permissão concedida
- **WHEN** o usuário aprova a permissão de microfone
- **THEN** o afinador e o visualizador de campo harmônico passam a capturar áudio

#### Scenario: Permissão negada
- **WHEN** o usuário nega a permissão de microfone
- **THEN** o app exibe uma mensagem explicativa com uma ação para reabrir as configurações do sistema, e o metrônomo permanece utilizável

### Requirement: Liberação de recursos de áudio
O sistema SHALL liberar o microfone e parar o processamento de áudio sempre que o utilitário dependente de microfone sair de primeiro plano.

#### Scenario: Sair do afinador
- **WHEN** o usuário sai do afinador ou coloca o app em segundo plano
- **THEN** a captura de microfone é interrompida para economizar bateria e CPU
