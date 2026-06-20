## Why

Guitarristas e músicos precisam de ferramentas práticas no dia a dia (afinar o instrumento, visualizar o campo harmônico de uma nota, manter o tempo), mas os apps disponíveis costumam ser utilitários isolados, com interfaces datadas e sem uma experiência visual envolvente. Este change cria um app mobile único que reúne as ferramentas essenciais com uma identidade visual deslumbrante e visualizações interativas — cordas que vibram, um círculo de campo harmônico e um metrônomo animado — transformando tarefas técnicas em uma experiência agradável e didática.

## What Changes

- Cria a fundação de um **app mobile (Flutter)** novo: estrutura de projeto, navegação por bottom-tab entre os utilitários, design system (tema, tipografia, cores, animações) e infraestrutura de permissões de microfone/áudio.
- Adiciona um **Afinador** com dois modos: cromático (detecta qualquer nota) e por corda (guiado para os 6 pares de cordas de violão/guitarra em afinação padrão E-A-D-G-B-E), com detecção de pitch em tempo real e visualização interativa das cordas.
- Adiciona um **Visualizador de Campo Harmônico** que, a partir de uma nota tocada/detectada ou selecionada, mostra o campo harmônico correspondente (maior/menor e seus acordes/graus) usando uma visualização circular interativa.
- Adiciona um **Metrônomo** com tempo (BPM) ajustável, compasso/assinatura de tempo configurável, acentos e uma animação de pêndulo simulando um metrônomo mecânico, com temporização precisa.
- Estabelece um serviço de áudio compartilhado (captura via microfone e análise de pitch) reutilizado pelo afinador e pelo visualizador.

## Capabilities

### New Capabilities
- `app-shell`: Estrutura base do app mobile — inicialização Flutter, navegação entre utilitários, design system visual (tema, cores, tipografia, animações base) e gerenciamento de permissões de microfone/áudio.
- `instrument-tuner`: Afinador cromático e por corda com detecção de pitch em tempo real via microfone, medição de afinação (centésimos/cent) e visualização interativa das cordas.
- `harmonic-field-visualizer`: Visualizador circular interativo do campo harmônico (maior/menor) gerado a partir da nota tocada/detectada ou selecionada, mostrando os graus e acordes correspondentes.
- `metronome`: Metrônomo com BPM e assinatura de compasso configuráveis, acentos de tempo, contagem precisa e animação de pêndulo.

### Modified Capabilities
<!-- Nenhuma capacidade existente — projeto novo (greenfield). -->

## Impact

- **Código**: Cria o monorepo/app Flutter do zero (`lib/` com feature packages para cada utilitário, `core/` para design system e serviços compartilhados de áudio).
- **Dependências (Flutter/Dart)**: pacotes de captura/áudio em tempo real (ex.: `flutter_audio_capture`/`record`/equivalente multiplataforma), algoritmo de detecção de pitch (ex.: autocorrelação/YIN), motor de animação e state management (ex.: Riverpod ou Provider).
- **Plataformas**: iOS e Android (metas iniciais); exige permissão de microfone (iOS `Info.plist` / Android `AndroidManifest.xml`).
- **Sem APIs/backend externos**: primeira versão 100% on-device e offline.
- **Risco técnico**: precisão de detecção de pitch em dispositivos, latência de áudio e timing preciso do metrônomo — endereçados em `design.md`.
